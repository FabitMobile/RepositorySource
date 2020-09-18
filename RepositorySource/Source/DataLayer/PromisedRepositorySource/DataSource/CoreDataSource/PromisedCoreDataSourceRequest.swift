import Foundation

open class PromisedCoreDataSourceRequest {
    public var entityClass: AnyClass

    public var predicate: NSPredicate?
    public var sortDescriptors: [NSSortDescriptor]?

    public var mappingDbToDomain: Mapping?

    public var limit: Int?

    public init(entityClass: AnyClass,
                predicate: NSPredicate? = nil,
                sortDescriptors: [NSSortDescriptor]? = nil,
                mappingDbToDomain: Mapping? = nil,
                limit: Int? = nil) {
        self.entityClass = entityClass
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.mappingDbToDomain = mappingDbToDomain
        self.limit = limit
    }
}
