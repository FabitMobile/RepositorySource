import Foundation
import PromiseKit

struct NilSelfError: Error {}

open class BasePromisedDataObserver<TQuery, TData>: PromisedDataObserverTypes,
    PromisedDataObserverFetcher {
    public typealias QueryType = TQuery
    public typealias DataType = TData
    public typealias PromisedDataObserverMapperBlock = (_ objects: [Any]) -> [DataType]

    public init() {}

    /**
     *  local source observer
     */
    fileprivate var frc: PromisedRepositoryFRC?
    fileprivate var onUpdate: PromisedDataObserverUpdateBlock?
    fileprivate var objectsMapper: PromisedDataObserverMapperBlock?

    open func bind(frc: PromisedRepositoryFRC,
                   onUpdate: @escaping PromisedDataObserverUpdateBlock,
                   objectsMapper: PromisedDataObserverMapperBlock? = nil) {
        self.onUpdate = onUpdate
        self.objectsMapper = objectsMapper

        self.frc = frc
        self.frc?.delegate = self

        frc.objects()
            .done { [weak self] result in
                guard let __self = self,
                    let frc = __self.frc else { return }
                __self.frc(frc, didUpdateObjects: result)
            }
            .catch { error in
                print("BasePromiseDataObserver ERROR: \(error)")
            }
    }

    // MARK: - paginator

    fileprivate var loadedIds: [Any] = []

    // MARK: - PromisedDataObserverFetcher

    public func objects() -> Promise<[TData]> {
        guard let frc = self.frc else { return Promise(error: NilSelfError()) }
        return frc.objects().compactMap { [weak self] (result) -> [TData]? in
            guard let __self = self else { return nil }

            var result = result
            if let objectsMapper = __self.objectsMapper {
                result = objectsMapper(result)
            }

            if let res = result as? [TData] {
                return res
            } else {
                return []
            }
        }
    }
}

extension BasePromisedDataObserver: PromisedRepositoryFRCDelegate {
    public func frc(_ frc: PromisedRepositoryFRC, didUpdateObjects objects: [Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let __self = self else { return }

            var objects = objects
            if let objectsMapper = __self.objectsMapper {
                objects = objectsMapper(objects)
            }
            if let objs = objects as? [TData] {
                __self.onUpdate?(objs)
            }
        }
    }
}

extension BasePromisedDataObserver: PromisedDataObserverUnsubscriber {
    public func unsubscribe() {
        frc = nil
        onUpdate = nil
        objectsMapper = nil
    }
}

extension BasePromisedDataObserver: PromisedDataObserverByIds {
    public func resetLoadedIds() {
        loadedIds = []
        frc?.predicate = PredicateFactory.inIds([])
    }

    public func appendIds(_ ids: [Any]) {
        loadedIds += ids
        frc?.predicate = PredicateFactory.inIds(loadedIds)
    }
}
