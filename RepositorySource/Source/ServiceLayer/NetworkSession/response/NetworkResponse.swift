import Foundation

open class NetworkResponse {
    open var httpStatus: Int?

    open var data: Data?
    open var json: Any?

    open var error: NSError?
}
