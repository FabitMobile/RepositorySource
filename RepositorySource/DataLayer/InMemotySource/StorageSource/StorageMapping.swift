import Foundation

public class StorageMapping<T: Decodable> {
    open var type: T.Type
    open var primaryKey: String?

    public init(type: T.Type,
                primaryKey: String) {
        self.primaryKey = primaryKey
        self.type = type
    }
}
