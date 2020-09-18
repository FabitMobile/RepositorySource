import Foundation

public struct PromisedRemoteSourceResponse {
    public let httpStatus: Int

    public var data: Data?
    public var json: Any?

    public let loadedIdentifiers: [Any]?

    public init(httpStatus: Int,
                data: Data?,
                json: Any?,
                loadedIdentifiers: [Any]?) {
        self.httpStatus = httpStatus

        self.data = data
        self.json = json

        self.loadedIdentifiers = loadedIdentifiers
    }
}
