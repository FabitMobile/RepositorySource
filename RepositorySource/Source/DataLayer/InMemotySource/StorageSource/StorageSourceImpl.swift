import Foundation
import FoundationExtension
import PromiseKit

public class StorageSourceImpl: StorageSource {
    var storage: Storage
    var notificationCenter: NotificationCenter

    var dataImportQueue: DispatchQueue

    public init(storage: Storage,
                notificationCenter: NotificationCenter) {
        self.storage = storage
        self.notificationCenter = notificationCenter

        dataImportQueue = DispatchQueue(label: "StorageSourceImpl.dataImportQueue")
    }

    // MARK: - API

    public func fetchData<T: Storable>(_ request: StorageSourceRequest<T>) -> Promise<[T]> {
        storage.fetch(predicate: request.predicate ?? { _ in true })
    }

    public func makeFrc<T>(_ request: StorageSourceRequest<T>) -> StorageSourceFRC<T> {
        StorageSourceFRC(storage: storage,
                         request: request,
                         notificationCenter: notificationCenter)
    }

    public func delete<T: Storable>(_ request: StorageSourceRequest<T>) -> Promise<Void> {
        storage.delete(predicate: request.predicate ?? { _ in true })
    }

    public func insertOrUpdate<T: Storable>(_ objects: [T]) -> Promise<Void> {
        storage.insertOrUpdate(elements: objects)
    }

    public func importJSON<T: Storable>(_ json: Any,
                                        mappingJsonToStorage: StorageMapping<T>) -> Promise<Void> {
        dataImportQueue.async(.promise) { () -> [[String: Any]] in
            if let array = json as? [[String: Any]] {
                return array
            } else if let json = json as? [String: Any] {
                return [json]
            }
            throw CastError()
        }
        .then(on: dataImportQueue, flags: nil) { jsonArray -> Promise<[T]> in
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: jsonArray, options: .fragmentsAllowed)
            let objects = try decoder.decode([T].self, from: data)
            return Promise.value(objects)
        }
        .then(on: dataImportQueue, flags: nil) { [weak self] (mappedObjects: [T]) -> Promise<Void> in
            guard let __self = self else { throw NilSelfError() }

            var resultObjects: [T] = mappedObjects.compactMap { $0 as T }

            if let oldObjects: [T] = try? __self.storage.fetch(predicate: { _ in true }).wait() {
                let newObjectsKeys: [String] = mappedObjects.map { $0.primaryKey() }

                let predicate = { (obj: T) -> Bool in
                    !newObjectsKeys.contains(obj.primaryKey())
                }

                resultObjects.append(contentsOf: oldObjects.filter { predicate($0) })
            }

            return __self.storage.insertOrUpdate(elements: resultObjects)
        }
    }
}
