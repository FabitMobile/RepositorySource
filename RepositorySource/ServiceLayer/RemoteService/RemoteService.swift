import Foundation
import PromiseKit
import Reachability
import UIKit

open class RemoteService {
    let baseURL: URL
    let session: NetworkSession
    let errorFactory: RemoteErrorFactory

    public init(config: RemoteServiceConfig,
                errorFactory: RemoteErrorFactory,
                logConfig: RemoteServiceLogConfig = .none) {
        var url = config.baseURL

        let path = url.absoluteString
        if path.isEmpty == false, path.hasSuffix("/") == false {
            // swiftlint:disable:next force_unwrapping
            url = URL(string: path.appending("/"))!
        }
        baseURL = url

        var networkLogConfig: NetworkSessionLogConfig = .none
        switch logConfig {
        case .none:
            networkLogConfig = .none

        case .all:
            networkLogConfig = .all

        case let .contains(strings):
            networkLogConfig = .contains(strings)
        }

        session = NetworkSession(configuration: config.sessionConfiguration,
                                 logConfig: networkLogConfig)

        self.errorFactory = errorFactory
    }

    // MARK: -

    open func execute(_ urlRequest: NetworkRequest) -> Promise<RemoteServiceResponse> {
        checkReachability()
            .then { [weak self] _ -> Promise<NetworkResponse> in
                guard let __self = self else { throw NilSelfError() }

                return when(fulfilled: __self.updateActivityIndicator(),
                            __self.session.runTask(with: urlRequest))
                    .map { $0.1 }
            }
            .then { [weak self] urlResponse -> Promise<RemoteServiceResponse> in
                guard let __self = self else { throw NilSelfError() }

                let remoteError = __self.errorFactory
                    .makeError(httpStatus: urlResponse.httpStatus ?? 0,
                               json: urlResponse.json,
                               networkError: urlResponse.error,
                               shouldConvertSuccessResultToJSON: urlRequest.shouldConvertSuccessResultToJSON)

                let remoteResponse = RemoteServiceResponse(httpStatus: urlResponse.httpStatus ?? 0,
                                                           data: urlResponse.data,
                                                           json: urlResponse.json,
                                                           error: remoteError)

                __self.updateActivityIndicator().cauterize()

                return Promise.value(remoteResponse)
            }
            .recover { Promise.value(RemoteServiceResponse(httpStatus: 0,
                                                           data: nil,
                                                           json: nil,
                                                           error: ($0 as Error?) as NSError?))
            }
    }

    func checkReachability() -> Promise<Void> {
        .init(resolver: { [weak self] seal in
            guard let __self = self else { seal.reject(NilSelfError()); return }
            guard let reachable = try? Reachability() else { seal.fulfill(()); return }
            if reachable.connection == .unavailable {
                seal.reject(__self.errorFactory.makeReachabilityError())
            }
            seal.fulfill(())
        })
    }

    func updateActivityIndicator() -> Promise<Void> {
        session.tasks()
            .then { data -> Promise<Void> in
                let (dataTasks, _, _) = data
                let hasRunning = !dataTasks.filter { (task) -> Bool in
                    task.state == URLSessionTask.State.running
                }.isEmpty
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = hasRunning
                }

                return .value(())
            }
    }
}
