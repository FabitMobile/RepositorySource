import Foundation

public typealias MappingAttributeBlock = (_ value: Any) -> Any?

open class MappingAttribute {
    open var property: String
    open var keyPath: String

    open var mappingBlock: MappingAttributeBlock?

    init(property: String,
         keyPath: String,
         mappingBlock: MappingAttributeBlock?) {
        self.property = property
        self.keyPath = keyPath
        self.mappingBlock = mappingBlock
    }

    convenience init(property: String,
                     keyPath: String) {
        self.init(property: property, keyPath: keyPath, mappingBlock: nil)
    }
}
