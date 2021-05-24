import Foundation
import PromiseKit

public class ObjectArrayNotFound: Error {}
public class CastError: Error {}

open class BaseStorage: Storage {
    var dataAccessQueue: DispatchQueue
    var notificationCenter: NotificationCenter

    public init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
        dataAccessQueue = DispatchQueue(label: "BaseStorage.dataAccessQueue")
    }

    // MARK: - StorageService

    open func allObjectsArrays() -> NSArray {
        fatalError("no implemented")
    }

    fileprivate func objectArray<T>(onQueue queue: DispatchQueue) -> Promise<ObjectArray<T>> {
        objectArray(forType: T.self, onQueue: queue)
    }

    fileprivate func objectArray<T>(forType type: T.Type, onQueue queue: DispatchQueue) -> Promise<ObjectArray<T>> {
        queue.async(.promise) { [weak self] () -> ObjectArray<T> in
            guard let __self = self else { throw NilSelfError() }

            for array in __self.allObjectsArrays() {
                guard let result = array as? ObjectArray<T> else { continue }
                return result
            }

            throw ObjectArrayNotFound()
        }
    }

    open func fetch<T: Storable>(predicate: @escaping SortPredicate<T>) -> Promise<[T]> {
        objectArray(onQueue: dataAccessQueue)
            .then(on: dataAccessQueue, flags: nil) { (array: ObjectArray<T>) -> Promise<[T]> in
                let result: [T] = array.value.filter { predicate($0) }
                return Promise.value(result)
            }
    }

    open func insertOrUpdate<T: Storable>(elements: [T]) -> Promise<Void> {
        insertOrUpdate(elements: elements, isSilent: false)
    }

    open func insertOrUpdate<T: Storable>(elements: [T], isSilent: Bool) -> Promise<Void> {
        objectArray(onQueue: dataAccessQueue)
            .then(on: dataAccessQueue, flags: nil) { [weak self] (array: ObjectArray<T>) -> Promise<Void> in
                guard let __self = self else { throw NilSelfError() }

                for element in elements {
                    if array.value.contains(where: { element.primaryValue() == $0.primaryValue() }) {
                        array.value.removeAll(where: { $0.primaryValue() == element.primaryValue() })
                    }
                    array.value.append(element)
                }

                if !isSilent {
                    __self.notificationCenter.post(name: NSNotification.Name.DidUpdateStorage, object: nil)
                }

                return Promise.value(())
            }
    }

    open func delete<T: Storable>(predicate: @escaping SortPredicate<T>) -> Promise<Void> {
        objectArray(onQueue: dataAccessQueue)
            .then(on: dataAccessQueue, flags: nil) { [weak self] (array: ObjectArray<T>) -> Promise<Void> in
                guard let __self = self else { throw NilSelfError() }

                let notPredicate: SortPredicate = { !predicate($0) }
                let elements = (array.value.filter { notPredicate($0) })

                array.value = elements
                __self.notificationCenter.post(name: NSNotification.Name.DidUpdateStorage, object: nil)

                return Promise.value(())
            }
    }
}
