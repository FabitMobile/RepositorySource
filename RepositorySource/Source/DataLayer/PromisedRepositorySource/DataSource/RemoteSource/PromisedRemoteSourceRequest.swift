import Foundation

public typealias RemoteSourceRequestBeforeImportBlock = (_ json: Any) -> Any

public class PromisedRemoteSourceRequest {
    public let networkRequest: NetworkRequest
    public var importInfo: PromisedRemoteSourceRequestImportInfo?

    public var errorHandlers: [PromisedRemoteSourceErrorHandler]

    public init(networkRequest: NetworkRequest,
                errorHandlers: [PromisedRemoteSourceErrorHandler],
                importInfo: PromisedRemoteSourceRequestImportInfo? = nil) {
        self.networkRequest = networkRequest
        self.importInfo = importInfo
        self.errorHandlers = errorHandlers
    }
}

public class PromisedRemoteSourceRequestImportInfo {
    public var localSourceForImport: PromisedCoreDataSource
    public var jsonKeyPath: String?
    public var mappingJsonToDb: Mapping

    public var beforeImportBlock: RemoteSourceRequestBeforeImportBlock?

    public init(localSourceForImport: PromisedCoreDataSource,
                jsonKeyPath: String? = nil,
                mappingJsonToDb: Mapping,
                beforeImportBlock: RemoteSourceRequestBeforeImportBlock? = nil) {
        self.localSourceForImport = localSourceForImport
        self.jsonKeyPath = jsonKeyPath
        self.mappingJsonToDb = mappingJsonToDb
        self.beforeImportBlock = beforeImportBlock
    }
}
