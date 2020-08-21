import Foundation
import PromiseKit

public protocol Storage {
    func fetch<T: Storable>(predicate: @escaping SortPredicate) -> Promise<[T]>
    func fetch<T: Storable>(type: T.Type, predicate: @escaping SortPredicate) -> Promise<[T]>

    func insertOrUpdate<T: Storable>(elements: [T]) -> Promise<Void>
    func insertOrUpdate<T: Storable>(elements: [T], isSilent: Bool) -> Promise<Void>

    func delete<T: Storable>(type: T.Type, predicate: @escaping SortPredicate) -> Promise<Void>
}
