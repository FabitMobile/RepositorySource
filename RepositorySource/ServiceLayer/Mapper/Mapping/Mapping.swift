import Foundation

open class Mapping {
    open var className: String
    open var primaryKey: String?

    open var attributes: [MappingAttribute]
    open var relationships: [MappingRelationship]

    public init(className: String,
                primaryKey: String?) {
        self.className = className
        self.primaryKey = primaryKey

        attributes = []
        relationships = []
    }

    open func entityClass() -> AnyClass {
        // swiftlint:disable:next force_unwrapping
        NSClassFromString(className)!
    }

    // MARK: -

    open func addAttributesFromDictionary(_ dictionary: [String: String]) {
        for (key, value) in dictionary {
            addAttribute(key, keyPath: value)
        }
    }

    open func addAttributesFromArray(_ array: [String]) {
        for item in array {
            addAttribute(item, keyPath: item)
        }
    }

    open func addAttribute(_ property: String, keyPath: String) {
        addAttribute(MappingAttribute(property: property, keyPath: keyPath))
    }

    open func addAttribute(_ property: String, keyPath: String, mappingBlock: @escaping MappingAttributeBlock) {
        addAttribute(MappingAttribute(property: property, keyPath: keyPath, mappingBlock: mappingBlock))
    }

    func addAttribute(_ attribute: MappingAttribute) {
        attributes.append(attribute)
    }

    // MARK: -

    open func addRelationship(_ property: String, keyPath: String, mapping: Mapping) {
        addRelationship(property, keyPath: keyPath, mapping: mapping, toMany: false)
    }

    open func addRelationship(_ property: String, keyPath: String, mapping: Mapping, toMany: Bool) {
        addRelationship(MappingRelationship(property: property, keyPath: keyPath, mapping: mapping, isToMany: toMany))
    }

    open func addRelationshipRecursive(_ property: String, keyPath: String, toMany: Bool) {
        addRelationship(MappingRelationship(property: property, keyPath: keyPath, mapping: nil, isToMany: toMany))
    }

    func addRelationship(_ relationship: MappingRelationship) {
        relationships.append(relationship)
    }
}
