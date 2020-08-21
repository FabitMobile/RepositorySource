import Foundation

public protocol PromisedDataObserverByIds: AnyObject {
    func resetLoadedIds()
    func appendIds(_ ids: [Any])
}
