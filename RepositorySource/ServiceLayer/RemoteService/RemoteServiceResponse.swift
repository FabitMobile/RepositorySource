import Foundation

public struct RemoteServiceResponse {
    public let httpStatus: Int

    public let data: Data?
    public let json: Any?

    public let error: Error?

    public init(httpStatus: Int, data: Data?, json: Any?, error: Error?) {
        self.httpStatus = httpStatus
        self.data = data
        self.json = json
        self.error = error
    }
}
