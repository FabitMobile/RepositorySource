import Foundation
import PromiseKit

public protocol PromisedRemoteSourceErrorHandler {
    func handle(error: Error,
                from request: PromisedRemoteSourceRequest) -> Promise<PromisedRemoteSourceErrorHandlerResponse>
}

public struct PromisedRemoteSourceErrorHandlerResponse {
    public let shouldRetryRequest: Bool
    public let newHeaders: [AnyHashable: String]?

    public init(shouldRetryRequest: Bool = false,
                newHeaders: [AnyHashable: String]? = nil) {
        self.shouldRetryRequest = shouldRetryRequest
        self.newHeaders = newHeaders
    }
}
