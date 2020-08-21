import Foundation

open class Storable: Equatable, Decodable {
    open func primaryKey() -> String {
        fatalError("does not implimented")
    }

    open func primaryValue() -> String {
        fatalError("does not implimented")
    }

    public static func == (lhs: Storable, rhs: Storable) -> Bool {
        false
    }
}
