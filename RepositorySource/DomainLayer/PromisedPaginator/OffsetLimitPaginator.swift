import Foundation
import FoundationExtension
import PromiseKit

struct NilLoaderError: Error {}
struct IsLoadingError: Error {}
struct CancelledError: Error {}

public struct OffsetLimitPaginatorData {
    
    public let loadedIds: [Any]
    public let total: Int
    
    public init(loadedIds: [Any],
                total: Int) {
        self.loadedIds = loadedIds
        self.total = total
    }
}

public typealias OffsetLimitPaginatorLoaderResponse = (PromisedRemoteSourceResponse, OffsetLimitPaginatorData)

public class OffsetLimitPaginator {
    public typealias LoaderClosure = (_ offset: Int, _ limit: Int) -> Promise<OffsetLimitPaginatorLoaderResponse>
    public typealias LoadedAllObjectsClosure = () -> Void

    public var observer: PromisedDataObserverByIds
    public var nextOffset: Int
    public var limit: Int

    public var loader: LoaderClosure?
    public var onLoadedAllObjects: LoadedAllObjectsClosure?

    public var isLoadingNextPage: Atomic<Bool>

    public init(observer: PromisedDataObserverByIds,
                limit: Int) {
        self.observer = observer
        nextOffset = 0
        self.limit = limit

        isLoadingNextPage = Atomic(value: false)
    }

    public convenience init(observer: PromisedDataObserverByIds) {
        self.init(observer: observer, limit: 20)
    }

    // MARK: - load

    public func refresh(loader: @escaping LoaderClosure,
                        onLoadedAllObjects: @escaping LoadedAllObjectsClosure) -> Promise<PromisedRemoteSourceResponse> {
        self.loader = loader
        self.onLoadedAllObjects = onLoadedAllObjects

        observer.resetLoadedIds()
        nextOffset = 0
        isLoadingNextPage.value = false

        return loadNext()
    }

    public func loadNext() -> Promise<PromisedRemoteSourceResponse> {
        guard let loader = loader else { return Promise(error: NilLoaderError()) }
        guard !isLoadingNextPage.value else { return Promise(error: IsLoadingError()) }
        isLoadingNextPage.value = true

        let offset = nextOffset
        let limit = self.limit
        return loader(offset, limit)
            .then { [weak self] (response) -> Promise<PromisedRemoteSourceResponse> in
                guard let __self = self else { throw NilSelfError() }
                guard offset == __self.nextOffset else { throw CancelledError() }

                __self.observer.appendIds(response.1.loadedIds)
                __self.nextOffset += __self.limit

                if __self.nextOffset >= response.1.total,
                    let onLoadedAllObjects = __self.onLoadedAllObjects {
                    DispatchQueue.main.async {
                        onLoadedAllObjects()
                    }
                }

                __self.isLoadingNextPage.value = false
                return Promise.value(response.0)
            }
    }
}
