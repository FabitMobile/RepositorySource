import Foundation
import PromiseKit

public protocol Storage {
    func fetch<T: Storable>(predicate: @escaping SortPredicate<T>) -> Promise<[T]>

    func insertOrUpdate<T: Storable>(elements: [T]) -> Promise<Void>
    func insertOrUpdate<T: Storable>(elements: [T], isSilent: Bool) -> Promise<Void>

    func delete<T: Storable>(predicate: @escaping SortPredicate<T>) -> Promise<Void>
}
