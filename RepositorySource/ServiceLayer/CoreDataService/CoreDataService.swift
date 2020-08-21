import CoreData
import Foundation

public extension Notification.Name {
    static let CoreDataDatabaseWasRemoved = Notification.Name("CoreDataDatabaseWasRemoved")
}

public struct EmptyPersistentStoresError: Error {}

// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping
open class CoreDataService {
    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    var managedObjectModel: NSManagedObjectModel!

    open var mainContext: NSManagedObjectContext!
    var persistingContext: NSManagedObjectContext!

    let dbSizeLimitBytes: Double = 50 * 1024 * 1024
    let notificationCenter: NotificationCenter

    public init(_ bundles: [Bundle] = [],
                notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
        setupCoreDataStack(bundles)
    }

    // MARK: - cd stack

    func setupCoreDataStack(_ bundles: [Bundle]) {
        mainContext = makeMainContext(bundles)
        persistingContext = mainContext.parent
    }

    // MARK: - Context

    func makeMainContext(_ bundles: [Bundle]) -> NSManagedObjectContext {
        let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        ctx.mergePolicy = NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType
        ctx.parent = makePersistentContext(bundles)

        if ctx.parent != nil {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(persistingContextDidSave(_:)),
                                                   name: NSNotification.Name.NSManagedObjectContextDidSave,
                                                   object: ctx.parent)
        }
        subscribeToWillSave(ctx)
        return ctx
    }

    func makePersistentContext(_ bundles: [Bundle]) -> NSManagedObjectContext {
        let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        ctx.mergePolicy = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
        ctx.persistentStoreCoordinator = makePersistentStoreCoordinator(bundles)
        subscribeToWillSave(ctx)
        return ctx
    }

    open func makeBackgroundContext() -> NSManagedObjectContext {
        let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        ctx.mergePolicy = NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType
        ctx.parent = persistingContext
        subscribeToWillSave(ctx)
        return ctx
    }

    func makeManagedObjectModel(_ bundles: [Bundle]) -> NSManagedObjectModel {
        guard let model = NSManagedObjectModel.mergedModel(from: !bundles.isEmpty ? bundles : nil) else {
            fatalError()
        }
        return model
    }

    // MARK: - PersistentStoreCoordinator

    func makePersistentStoreCoordinator(_ bundles: [Bundle]) -> NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeManagedObjectModel(bundles))
        openPersistentStore(coordinator)
        return coordinator
    }

    func openPersistentStore(_ coordinator: NSPersistentStoreCoordinator) {
        checkSize()

        let storeUrl = storeURL()
        var directoryUrl = storeUrl.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: directoryUrl,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print(">>CoreDataService: ERROR: \(error)")
        }

        let options: [String: Any] = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "WAL"]
        ]
        do {
            try _ = coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                   configurationName: nil,
                                                   at: storeUrl,
                                                   options: options)
        } catch {
            print(">>CoreDataService: ERROR: failed to addPersistentStore, \(error)")

            let error = error as NSError
            let isMigrationError = error.code == NSPersistentStoreIncompatibleVersionHashError
                || error.code == NSMigrationMissingSourceModelError
                || error.code == NSMigrationError
                || error.code == NSMigrationMissingMappingModelError
            if isMigrationError, error.domain == NSCocoaErrorDomain {
                print(">>CoreDataService: ERROR: migration error, will try to cleanup and readd store")

                try? FileManager.default.removeItem(at: storeUrl)

                let shmURL = URL(string: storeUrl.absoluteString.appending("-shm"))!
                try? FileManager.default.removeItem(at: shmURL)

                let walURL = URL(string: storeUrl.absoluteString.appending("-wal"))!
                try? FileManager.default.removeItem(at: walURL)

                do {
                    _ = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                           configurationName: nil,
                                                           at: storeUrl,
                                                           options: options)
                    print(">>CoreDataService: readded successfully")
                } catch {
                    print(">>CoreDataService: ERROR: finally failed to readd store, \(error)")
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let __self = self else { return }
                    __self.notificationCenter.post(name: NSNotification.Name.CoreDataDatabaseWasRemoved, object: nil)
                }
            }
        }

        excludeFromBackup(directoryUrl: &directoryUrl)
    }

    // Inout is set here to show that URL configuration is changed by changing its URLResourceValues
    func excludeFromBackup(directoryUrl: inout URL) {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true

        do {
            try directoryUrl.setResourceValues(values)
            let files = try FileManager.default.contentsOfDirectory(at: directoryUrl,
                                                                    includingPropertiesForKeys: nil,
                                                                    options: [])
            for var file in files {
                try file.setResourceValues(values)
            }
        } catch {
            print(">>CoreDataService: ERROR: setResourceValues \(error)")
        }
    }

    func checkSize() {
        let storeUrl = storeURL()

        let path = storeUrl.path
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            let fileSize = attributes[FileAttributeKey.size] as! NSNumber

            let size = fileSize.doubleValue
            let max = dbSizeLimitBytes
            if size > max {
                try FileManager.default.removeItem(at: storeUrl)
                print(">>CoreDataService: INFO: removedDB")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let __self = self else { return }
                    __self.notificationCenter.post(name: NSNotification.Name.CoreDataDatabaseWasRemoved, object: nil)
                }
            }
        } catch {
            print(">>CoreDataService: ERROR: \(error)")
        }
    }

    func storeURL() -> URL {
        let appName = Bundle.main.bundleIdentifier!.components(separatedBy: ".").last!
        var path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationSupportDirectory,
                                                       FileManager.SearchPathDomainMask.userDomainMask,
                                                       true).last!
        path.append(String(format: "/%@", appName))
        path.append(String(format: "/%@.sqlite", appName))
        let url = URL(fileURLWithPath: path, isDirectory: false)
        return url
    }

    // MARK: - save notifications

    @objc
    func persistingContextDidSave(_ notification: Notification) {
        guard let ctx = notification.object as? NSManagedObjectContext,
            ctx == persistingContext else { return }

        mainContext.perform { [weak self] in
            guard let __self = self else { return }

            guard let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> else {
                return
            }
            updatedObjects.map { $0.objectID }.forEach { [weak self] objectID in
                guard let __self = self else { return }
                guard let object = try? __self.mainContext.existingObject(with: objectID) else {
                    return
                }
                object.willAccessValue(forKey: nil)
            }
            __self.mainContext.mergeChanges(fromContextDidSave: notification)
        }
    }

    func subscribeToWillSave(_ context: NSManagedObjectContext) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextWillSave(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextWillSave,
                                               object: context)
    }

    @objc
    func managedObjectContextWillSave(_ notification: Notification) {
        let ctx = notification.object as! NSManagedObjectContext
        let insertedObjects = ctx.insertedObjects
        if !insertedObjects.isEmpty {
            do {
                try ctx.obtainPermanentIDs(for: Array(insertedObjects))
            } catch {
                print(">>CoreDataService: ERROR: failed to obtainPermanentIDs, \(error)")
            }
        }
    }

    // MARK: - fetch

    open func fetch<T>(_ request: NSFetchRequest<T>, inContext context: NSManagedObjectContext) -> [T] {
        var result: [T] = []
        do {
            result = try context.fetch(request)
        } catch {
            print(">>CoreDataService: ERROR: failed to execute request, \(error)")
        }
        return result
    }

    open func count(_ request: NSFetchRequest<NSManagedObject>, inContext context: NSManagedObjectContext) -> Int {
        var count: Int = 0
        do {
            count = try context.count(for: request)
        } catch {
            print(">>CoreDataService: ERROR: failed to execute request, \(error)")
        }
        return count
    }

    open func makeFetchRequest(_ entityClass: AnyClass,
                               predicate: NSPredicate?,
                               sortDescriptors: [NSSortDescriptor]?,
                               offset: Int?,
                               limit: Int?) -> NSFetchRequest<NSManagedObject> {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: NSStringFromClass(entityClass))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if let offset = offset {
            request.fetchOffset = offset
        }
        if let limit = limit {
            request.fetchLimit = limit
        }
        return request
    }

    open func makeFrc(_ fetchRequest: NSFetchRequest<NSManagedObject>) -> NSFetchedResultsController<NSManagedObject> {
        let ctrl = NSFetchedResultsController(fetchRequest: fetchRequest,
                                              managedObjectContext: mainContext,
                                              sectionNameKeyPath: nil,
                                              cacheName: nil)
        return ctrl
    }

    open func data<T>(_ objects: [T], inContext context: NSManagedObjectContext) -> [T] {
        objects.map { context.object(with: ($0 as! NSManagedObject).objectID) } as! [T]
    }

    // MARK: - save

    open func saveContext(_ context: NSManagedObjectContext) throws {
        var saveError: Error?

        context.performAndWait { [weak self] in
            guard let __self = self else { return }
            if context.hasChanges {
                do {
                    try context.save()

                    if let parentContext = context.parent {
                        try __self.saveContext(parentContext)
                    }
                } catch {
                    print(">>CoreDataService: ERROR: failed to save context, \(error)")
                    saveError = error
                }
            }
        }
        if let error = saveError {
            throw error
        }
    }
}
