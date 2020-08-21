import Foundation
import PromiseKit

public protocol PromisedRemoteSource {
    /// Give a promise to execute remote request
    ///
    /// - Parameter request:
    /// - Returns: promise to make request
    func execute(_ request: PromisedRemoteSourceRequest) -> Promise<PromisedRemoteSourceResponse>
}
