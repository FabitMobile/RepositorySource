import Foundation

public struct HttpError: Error {
    static func isHttpError(_ httpStatus: Int) -> Bool { httpStatus >= 400 && httpStatus < 600 }

    public let httpStatus: Int
    public let apiError: ApiError?

    public init(httpStatus: Int,
                apiError: ApiError?) {
        self.httpStatus = httpStatus
        self.apiError = apiError
    }

    public var isClientError: Bool {
        httpStatus >= 400 && httpStatus < 500
    }

    public var isServerError: Bool {
        httpStatus >= 500 && httpStatus < 600
    }

    public enum HttpErrorStatus {
        case unauthorized, forbidden, otherClientError
        case internalServerError, otherServerError
    }

    public var httpErrorStatus: HttpErrorStatus {
        if isClientError {
            if httpStatus == 401 {
                return .unauthorized
            } else if httpStatus == 403 {
                return .forbidden
            } else {
                return .otherClientError
            }
        } else {
            if httpStatus == 501 {
                return .internalServerError
            } else {
                return .otherServerError
            }
        }
    }
}
