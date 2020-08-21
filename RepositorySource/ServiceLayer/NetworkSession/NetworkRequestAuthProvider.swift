import Foundation
import PromiseKit

public protocol NetworkRequestAuthProvider {
    func authHeaders() -> Promise<[String: String]>
}
