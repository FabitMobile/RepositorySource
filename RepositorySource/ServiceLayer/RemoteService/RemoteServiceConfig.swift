import Foundation

public class RemoteServiceConfig {
    public let sessionConfiguration: URLSessionConfiguration
    public let baseURL: URL

    public init(sessionConfiguration: URLSessionConfiguration,
                baseURL: URL) {
        self.sessionConfiguration = sessionConfiguration
        self.baseURL = baseURL
    }
}

public enum RemoteServiceLogConfig {
    case none
    case all
    case contains([String])
}
