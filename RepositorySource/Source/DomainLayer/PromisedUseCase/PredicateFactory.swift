import Foundation

public class PredicateFactory {
    public static func byId(_ identifier: Any) -> NSPredicate {
        NSPredicate(format: "identifier == %@", argumentArray: [identifier])
    }

    public static func inIds(_ identifiers: [Any]) -> NSPredicate {
        NSPredicate(format: "identifier IN %@", identifiers)
    }

    public static func notInIds(_ identifiers: [Any]) -> NSPredicate {
        not(inIds(identifiers))
    }

    public static func and(_ predicates: [NSPredicate]) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func or(_ predicates: [NSPredicate]) -> NSPredicate {
        NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }

    public static func not(_ predicate: NSPredicate) -> NSPredicate {
        NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
    }
}
