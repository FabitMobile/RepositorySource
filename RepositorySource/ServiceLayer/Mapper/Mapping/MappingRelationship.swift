import Foundation

open class MappingRelationship {
    open var property: String
    open var keyPath: String

    open var mapping: Mapping?

    open var isToMany: Bool
    open var isRecursive: Bool

    init(property: String,
         keyPath: String,
         mapping: Mapping?,
         isToMany: Bool) {
        self.property = property
        self.keyPath = keyPath

        self.mapping = mapping
        isRecursive = mapping == nil

        self.isToMany = isToMany
    }

    convenience init(property: String,
                     keyPath: String,
                     mapping: Mapping?) {
        self.init(property: property, keyPath: keyPath, mapping: mapping, isToMany: false)
    }
}
