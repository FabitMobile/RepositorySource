import CoreData
import FastEasyMapping
import Foundation

// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping
open class Mapper {
    public init() {}

    open func transform(source: Any, mapping: Mapping, context: Any?) -> [Any] {
        var result: [Any] = []

        let femMapping = makeFEMMapping(mapping)
        let useCoreData = femMapping.entityName != nil

        if let collection = source as? [Any] {
            if useCoreData == true {
                result = FEMDeserializer.collection(fromRepresentation: collection,
                                                    mapping: femMapping,
                                                    context: context as! NSManagedObjectContext)
            } else {
                result = FEMDeserializer.collection(fromRepresentation: collection, mapping: femMapping)
            }
        } else {
            let dictionary = source as! [AnyHashable: Any]
            if useCoreData == true {
                result = [FEMDeserializer.object(fromRepresentation: dictionary,
                                                 mapping: femMapping,
                                                 context: context as! NSManagedObjectContext)]
            } else {
                result = [FEMDeserializer.object(fromRepresentation: dictionary, mapping: femMapping)]
            }
        }

        return result
    }

    fileprivate func makeFEMMapping(_ mapping: Mapping) -> FEMMapping {
        let objClass: AnyClass = mapping.entityClass()
        let femMapping: FEMMapping
        if objClass is NSManagedObject.Type {
            femMapping = FEMMapping(entityName: mapping.className)
        } else {
            femMapping = FEMMapping(objectClass: objClass)
        }

        femMapping.primaryKey = mapping.primaryKey

        for attribute in mapping.attributes {
            let femAttribute = FEMAttribute(property: attribute.property,
                                            keyPath: attribute.keyPath,
                                            map: attribute.mappingBlock,
                                            reverseMap: nil)
            femMapping.addAttribute(femAttribute)
        }

        for relation in mapping.relationships {
            let femRelationMapping = relation.isRecursive == true ? femMapping : makeFEMMapping(relation.mapping!)
            let femRelation = FEMRelationship(property: relation.property,
                                              keyPath: relation.keyPath,
                                              mapping: femRelationMapping)
            femRelation.isToMany = relation.isToMany

            femMapping.addRelationship(femRelation)
        }

        return femMapping
    }
}
