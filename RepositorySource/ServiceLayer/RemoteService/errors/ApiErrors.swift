import Foundation

public struct ApiError: Error {
    public let name: String
    public let text: String
    public let userMessage: String

    public init(name: String, text: String, userMessage: String) {
        self.name = name
        self.text = text
        self.userMessage = userMessage
    }
}
