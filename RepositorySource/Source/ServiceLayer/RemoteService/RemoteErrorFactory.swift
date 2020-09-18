import Foundation

public protocol RemoteErrorFactory {
    func makeError(httpStatus: Int,
                   json: Any?,
                   networkError: NSError?,
                   shouldConvertSuccessResultToJSON: Bool) -> Error?
}

public extension RemoteErrorFactory {
    func makeReachabilityError() -> ReachabilityError {
        ReachabilityError()
    }
}

open class DefaultRemoteErrorFactory: RemoteErrorFactory {
    public init() {}

    // MARK: - make

    public func makeError(httpStatus: Int,
                          json: Any?,
                          networkError: NSError?,
                          shouldConvertSuccessResultToJSON: Bool) -> Error? {
        if let error = makeSessionError(networkError: networkError) {
            return error

        } else if let error = makeTimeOutError(httpStatus: httpStatus, json: json, networkError: networkError) {
            return error

        } else if let error = makeHttpError(httpStatus: httpStatus, json: json, networkError: networkError) {
            return error

        } else if shouldConvertSuccessResultToJSON,
            let error = makeApiError(httpStatus: httpStatus, json: json, networkError: networkError) {
            return error
        }

        return nil
    }

    func makeSessionError(networkError: NSError?) -> SessionError? {
        if networkError is NetworkSessionError {
            return SessionError()
        } else {
            return nil
        }
    }

    func makeTimeOutError(httpStatus: Int, json: Any?, networkError: NSError?) -> TimeOutError? {
        if let error = networkError,
            TimeOutError.isTimeOutError(error.code) {
            return TimeOutError(name: error.domain, userMessage: error.domain)
        }
        return nil
    }

    func makeHttpError(httpStatus: Int, json: Any?, networkError: NSError?) -> HttpError? {
        guard HttpError.isHttpError(httpStatus) else { return nil }

        let apiError = makeApiError(httpStatus: httpStatus, json: json, networkError: networkError)
        return HttpError(httpStatus: httpStatus, apiError: apiError)
    }

    open func makeApiError(httpStatus: Int, json: Any?, networkError: NSError?) -> ApiError? {
        nil
    }
}
