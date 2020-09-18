import Foundation

public protocol Storable: Equatable, Decodable {
    func primaryKey() -> String
    func primaryValue() -> String
}
