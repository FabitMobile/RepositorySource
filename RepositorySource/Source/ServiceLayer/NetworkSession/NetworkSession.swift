import Foundation
import PromiseKit

public typealias NetworkSessionTasks = ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])

public enum NetworkSessionLogConfig {
    case none
    case all
    case contains([String])
}

open class NetworkSession {
    let kNetworkSession_httpStatus_taskInvalid = -1
    let kNetworkSession_httpStatus_taskCancelled = -2

    var session: URLSession
    var queue: DispatchQueue
    let logConfig: NetworkSessionLogConfig

    public init(configuration: URLSessionConfiguration,
                logConfig: NetworkSessionLogConfig = .none) {
        session = URLSession(configuration: configuration)
        queue = DispatchQueue(label: "com.NetworkSession.queue")
        self.logConfig = logConfig
    }

    // MARK: - task

    // swiftlint:disable function_body_length
    open func runTask(with request: NetworkRequest) -> Promise<NetworkResponse> {
        let authHeadersPromise: Promise<[String: String]>

        if let networkRequestAuthProvider = request.networkRequestAuthProvider {
            authHeadersPromise = networkRequestAuthProvider.authHeaders()
        } else {
            authHeadersPromise = .value([:])
        }

        return authHeadersPromise
            .then { [weak self] additionalHeaders -> Promise<NetworkResponse> in
                var taskRequest = request.urlRequest()

                for header in additionalHeaders {
                    taskRequest.setValue(header.value, forHTTPHeaderField: header.key)
                }

                return .init(resolver: { [weak self] seal in
                    guard let __self = self else { seal.reject(NilSelfError()); return }

                    __self.logWillSend(request: request)
                    __self.session.dataTask(with: taskRequest) { [weak self] data, networkResponse, error in
                        guard let __self = self else { return }

                        __self.queue.async {
                            var taskError: NetworkSessionError?

                            if let unwrappedError = error {
                                let nsError = unwrappedError as NSError
                                if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                                    taskError = NetworkSessionTaskCancelledError(domain: nsError.domain,
                                                                                 code: nsError.code,
                                                                                 userInfo: nsError.userInfo)
                                } else {
                                    taskError = NetworkSessionNetworkError(domain: nsError.domain,
                                                                           code: nsError.code,
                                                                           userInfo: nsError.userInfo)
                                }
                            }

                            let response = NetworkResponse()
                            response.httpStatus = (networkResponse as? HTTPURLResponse)?.statusCode
                            response.data = data

                            let isHttpError = HttpError.isHttpError(response.httpStatus ?? 500)
                            let shouldConvertResultToJSON = (isHttpError || request.shouldConvertSuccessResultToJSON)
                                && response.httpStatus != 204

                            if shouldConvertResultToJSON, taskError == nil {
                                guard let data = data else {
                                    response.error = NetworkSessionDataError()
                                    DispatchQueue.main.async {
                                        seal.fulfill(response)
                                    }
                                    return
                                }

                                do {
                                    let options: JSONSerialization.ReadingOptions = [
                                        .allowFragments,
                                        .mutableContainers,
                                        .mutableLeaves
                                    ]
                                    response.json = try JSONSerialization.jsonObject(with: data,
                                                                                     options: options)
                                    //                        print(response.json)
                                } catch {
                                    let userInfo = [
                                        "dataUTF8": String(data: data, encoding: .utf8) as Any,
                                        "jsonError": (error as NSError).userInfo
                                    ]
                                    taskError = NetworkSessionJSONError(domain: (error as NSError).domain,
                                                                        code: (error as NSError).code,
                                                                        userInfo: userInfo)
                                }
                            }

                            response.error = taskError
                            __self.logDidReceive(response: response, for: request)

                            DispatchQueue.main.async {
                                seal.fulfill(response)
                            }
                        }
                    }.resume()
                })
            }
    }

    open func tasks() -> Promise<NetworkSessionTasks> {
        .init(resolver: { [weak self] seal in
            guard let __self = self else { seal.reject(NilSelfError()); return }

            __self.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTask in
                seal.fulfill((dataTasks, uploadTasks, downloadTask))
            }
        })
    }

    // MARK: - logs

    func logWillSend(request: NetworkRequest) {
        guard shouldLog(request: request) else { return }

        guard let url = request.urlRequest().url else { return }
        print("NetworkSession: will send:\n\(Date())\n\(url.absoluteString)")
    }

    func logDidReceive(response: NetworkResponse, for request: NetworkRequest) {
        guard shouldLog(request: request) else { return }

        let urlRequest = request.urlRequest()
        guard let url = urlRequest.url else { return }
        print("""
        NetworkSession: did receive:
        url:     \(url.absoluteString)
        headers: \(String(describing: urlRequest.allHTTPHeaderFields))
        body: \(String(describing: try? JSONSerialization.jsonObject(with: urlRequest.httpBody ?? Data(), options: [])))
        status:  \(String(describing: response.httpStatus))
        json:    \(String(describing: response.json))
        """)
    }

    func shouldLog(request: NetworkRequest) -> Bool {
        let urlRequest = request.urlRequest()
        guard let url = urlRequest.url else { return false }
        switch logConfig {
        case .none:
            return false

        case .all:
            return true

        case let .contains(strings):
            for str in strings {
                if url.absoluteString.contains(str) {
                    return true
                }
            }
            return false
        }
    }
}
