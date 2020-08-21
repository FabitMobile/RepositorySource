import Foundation
import PromiseKit

class MappingContext {
    fileprivate var storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    func object<T: Storable>(primaryKey: String, value: Any) -> Promise<T> {
        let predicate: SortPredicate = { $0.primaryValue() == "\(value)" }
        return storage.fetch(predicate: predicate).firstValue
    }

    func save<T: Storable>(object: T) -> Promise<Void> {
        storage.insertOrUpdate(elements: [object], isSilent: true)
    }
}
