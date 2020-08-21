import CoreData
import Foundation
import PromiseKit

open class PromisedCoreDataSourceFRC: NSObject {
    fileprivate var coreDataService: CoreDataService
    fileprivate var frc: NSFetchedResultsController<NSManagedObject>

    fileprivate var mappingDbToDomain: Mapping?

    fileprivate var queue: DispatchQueue

    public init(frc: NSFetchedResultsController<NSManagedObject>,
                coreDataService: CoreDataService,
                mappingDbToDomain: Mapping?) {
        self.frc = frc

        self.mappingDbToDomain = mappingDbToDomain
        self.coreDataService = coreDataService

        queue = DispatchQueue(label: "RepositoryCoreDataObserverImpl")

        super.init()

        frc.delegate = self
        performFetch()
    }

    // MARK: PromisedRepositoryFRC

    open weak var delegate: PromisedRepositoryFRCDelegate?

    fileprivate func performFetch() {
        queue.async { [weak self] in
            guard let __self = self else { return }
            try? __self.frc.performFetch()
        }
    }

    fileprivate func fetchedObjects() -> Guarantee<[NSManagedObject]> {
        queue.async(.promise) { [weak self] () -> [NSManagedObject] in
            guard let __self = self else { throw NilSelfError() }
            return __self.frc.fetchedObjects ?? []
        }
        .recover { (_) -> Guarantee<[NSManagedObject]> in
            .value([])
        }
    }
}

extension PromisedCoreDataSourceFRC: PromisedRepositoryFRC {
    open var predicate: NSPredicate? {
        get {
            frc.fetchRequest.predicate
        }
        set(newValue) {
            frc.fetchRequest.predicate = newValue
            performFetch()

            guard let frc = frc as? NSFetchedResultsController<NSFetchRequestResult> else { return }
            controllerDidChangeContent(frc)
        }
    }

    public func objects() -> Guarantee<[Any]> {
        Guarantee(resolver: { [weak self] seal in
            guard let __self = self else { return }

            let ctx = __self.coreDataService.makeBackgroundContext()
            ctx.perform { [weak self] in
                guard let __self = self else { return }

                __self.fetchedObjects()
                    .done { fetchedObjects in

                        var resultObjects: [Any] = []

                        if let mappingDbToDomain = __self.mappingDbToDomain {
                            let fetchedObjectsInCtx = __self.coreDataService.data(fetchedObjects, inContext: ctx)
                            resultObjects = Mapper().transform(source: fetchedObjectsInCtx,
                                                               mapping: mappingDbToDomain,
                                                               context: nil)
                        } else {
                            resultObjects = fetchedObjects
                        }

                        seal(resultObjects)
                    }
            }
        })
    }
}

extension PromisedCoreDataSourceFRC: NSFetchedResultsControllerDelegate {
    open func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        objects()
            .done { [weak self] result in
                guard let __self = self,
                    let delegate = __self.delegate else { return }

                delegate.frc(__self, didUpdateObjects: result)
            }
            .catch { error in
                print("PromisedCoreDataSourceFRC ERROR: \(error)")
            }
    }
}
