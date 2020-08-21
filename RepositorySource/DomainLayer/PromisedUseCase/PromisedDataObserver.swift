import Foundation
import PromiseKit

public protocol PromisedDataObserver: PromisedDataObserverSubscriber, PromisedDataObserverFetcher {}

public protocol PromisedDataObserverTypes: AnyObject {
    associatedtype QueryType
    associatedtype DataType
    typealias PromisedDataObserverUpdateBlock = (_ objects: [DataType]) -> Void
}

public protocol PromisedDataObserverSubscriber: PromisedDataObserverTypes {
    /**
     *  subscribe to data updates
     */
    func subscribe(_ query: QueryType, _ onUpdate: @escaping PromisedDataObserverUpdateBlock)
}

public protocol PromisedDataObserverFetcher: PromisedDataObserverTypes {
    /**
     * refetch objects
     */
    func objects() -> Promise<[DataType]>
}

public protocol PromisedDataObserverUnsubscriber {
    /**
     * stop listening to updates
     */
    func unsubscribe()
}
