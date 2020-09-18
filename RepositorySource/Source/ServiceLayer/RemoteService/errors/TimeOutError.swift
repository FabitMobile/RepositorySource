import Foundation

public struct TimeOutError: Error {
    public let name: String
    public let userMessage: String

    init(name: String, userMessage: String) {
        self.name = name
        self.userMessage = userMessage
    }

    static func isTimeOutError(_ errorCode: Int) -> Bool {
        errorCode == -1001
    }
}
