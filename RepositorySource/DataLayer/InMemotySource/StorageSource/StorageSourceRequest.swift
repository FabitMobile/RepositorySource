import Foundation

public typealias SortPredicate<T: Storable> = (T) -> Bool

public class StorageSourceRequest<T: Storable> {
    public var predicate: SortPredicate<T>?

    public init(predicate: SortPredicate<T>? = nil) {
        self.predicate = predicate
    }
}
