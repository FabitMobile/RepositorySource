import Foundation
import PromiseKit

public protocol PromisedUseCase {
    associatedtype Query
    associatedtype ResponseType

    /**
     * execute operation
     */
    func execute(_ query: Query) -> Promise<ResponseType>
}
