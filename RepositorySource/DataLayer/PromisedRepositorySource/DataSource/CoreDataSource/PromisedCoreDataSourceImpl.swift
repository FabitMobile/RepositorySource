import CoreData
import Foundation
import PromiseKit

extension NSManagedObjectContext: PromisedCoreDataSourceContext {}

open class PromisedCoreDataSourceImpl {
    open var coreDataService: CoreDataService

    open var importQueue: DispatchQueue

    public init(coreDataService: CoreDataService, importQueue: DispatchQueue) {
        self.coreDataService = coreDataService
        self.importQueue = importQueue
    }
}

extension PromisedCoreDataSourceImpl: PromisedCoreDataSource {
    // MARK: fetch

    public func fetchData<T>(_ request: PromisedCoreDataSourceRequest) -> Guarantee<[T]> {
        Guarantee(resolver: { [weak self] seal in
            guard let __self = self else { return }

            var result: [T] = []
            let ctx = __self.coreDataService.makeBackgroundContext()

            ctx.performAndWait { [weak self] in
                guard let __self = self else { return }
                result.append(contentsOf: __self.fetchData(request, inContext: ctx))
            }

            seal(result)
        })
    }

    public func fetchData<T>(_ request: PromisedCoreDataSourceRequest,
                             inContext context: PromisedCoreDataSourceContext) -> [T] {
        guard let ctx = context as? NSManagedObjectContext else { return [] }
        let fetchRequest = coreDataService.makeFetchRequest(request.entityClass,
                                                            predicate: request.predicate,
                                                            sortDescriptors: request.sortDescriptors,
                                                            offset: nil,
                                                            limit: request.limit)
        let dataObjects = coreDataService.fetch(fetchRequest, inContext: ctx)

        var result: [T] = []
        if let mappingDbToDomain = request.mappingDbToDomain,
            let domainObjects = Mapper().transform(source: dataObjects,
                                                   mapping: mappingDbToDomain,
                                                   context: nil) as? [T] {
            result = domainObjects

        } else if let objects = dataObjects as? [T] {
            result = objects
        }
        return result
    }

    public func count(_ request: PromisedCoreDataSourceRequest) -> Guarantee<Int> {
        Guarantee(resolver: { [weak self] seal in
            guard let __self = self else { return }

            var result = 0
            let ctx = __self.coreDataService.makeBackgroundContext()

            ctx.performAndWait { [weak self] in
                guard let __self = self else { return }
                result = __self.count(request, inContext: ctx)
            }

            seal(result)
        })
    }

    public func count(_ request: PromisedCoreDataSourceRequest,
                      inContext context: PromisedCoreDataSourceContext) -> Int {
        let fetchRequest = coreDataService.makeFetchRequest(request.entityClass,
                                                            predicate: request.predicate,
                                                            sortDescriptors: request.sortDescriptors,
                                                            offset: nil,
                                                            limit: request.limit)
        let context = coreDataService.makeBackgroundContext()
        return coreDataService.count(fetchRequest, inContext: context)
    }

    public func makeFrc(_ request: PromisedCoreDataSourceRequest) -> PromisedRepositoryFRC {
        let fetchRequest = coreDataService.makeFetchRequest(request.entityClass,
                                                            predicate: request.predicate,
                                                            sortDescriptors: request.sortDescriptors,
                                                            offset: nil,
                                                            limit: request.limit)
        let frc = coreDataService.makeFrc(fetchRequest)
        let sourceFRC = PromisedCoreDataSourceFRC(frc: frc,
                                                  coreDataService: coreDataService,
                                                  mappingDbToDomain: request.mappingDbToDomain)
        return sourceFRC
    }

    // MARK: save

    public func saveAsync(_ block: @escaping PromisedCoreDataSourceActionBlock) -> Promise<Bool> {
        Promise(resolver: { [weak self] seal in
            guard let __self = self else { return }

            let ctx = __self.coreDataService.makeBackgroundContext()

            ctx.performAndWait { [weak self] in
                guard let __self = self else { return }
                do {
                    try block(ctx)
                    try __self.coreDataService.saveContext(ctx)
                    seal.fulfill(true)
                } catch {
                    seal.reject(error)
                }
            }
        })
    }

    //    // MARK: delete
    public func deleteAsync(_ request: PromisedCoreDataSourceRequest) -> Promise<Bool> {
        saveAsync { [weak self] ctx in
            guard let __self = self else { return }
            __self.delete(request, inContext: ctx)
        }
    }

    public func delete(_ request: PromisedCoreDataSourceRequest,
                       inContext context: PromisedCoreDataSourceContext) {
        let objects: [NSManagedObject] = fetchData(request, inContext: context)
        delete(objects, inContext: context)
    }

    func delete(_ objects: [NSManagedObject], inContext context: PromisedCoreDataSourceContext) {
        // swiftlint:disable force_cast

        let ctx = context as! NSManagedObjectContext
        objects.forEach { ctx.delete($0) }

        // swiftlint:enable force_cast
    }

    // MARK: import

    public func importJSON(_ json: Any,
                           mappingJsonToDb: Mapping) -> Promise<Bool> {
        let savePromise = saveAsync { ctx in
            _ = Mapper().transform(source: json, mapping: mappingJsonToDb, context: ctx)
        }

        return Promise(resolver: { $0.fulfill(true) })
            .then(on: importQueue) { _ in
                savePromise
            }
    }
}
