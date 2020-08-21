import Foundation

public typealias SortPredicate = (Storable) -> Bool

public class StorageSourceRequest {
    public var entity: Storable.Type
    public var predicate: SortPredicate?

    public init(entity: Storable.Type,
                predicate: SortPredicate? = nil) {
        self.entity = entity

        self.predicate = predicate
    }
}
