import Foundation

public protocol PromisedRepoWithCDSource {
    var coreDataSource: PromisedCoreDataSource { get set }

    // MARK: - class

    func dataClass() -> AnyClass
    func domainClass() -> AnyClass

    // MARK: - mapping

    func mappingDbToDomain() -> Mapping
    func mappingJsonToDb() -> Mapping
}

extension PromisedRepoWithCDSource {
    // MARK: - mapping

    public func mappingDbToDomain() -> Mapping {
        // swiftlint:disable:next force_cast
        let t: Mappable.Type = domainClass().self as! Mappable.Type
        return t.defaultMapping()
    }

    public func mappingJsonToDb() -> Mapping {
        // swiftlint:disable:next force_cast
        let t: Mappable.Type = dataClass().self as! Mappable.Type
        return t.defaultMapping()
    }
}
