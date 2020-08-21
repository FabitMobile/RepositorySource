import Foundation

public enum NetworkRequestHTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

public enum NetworkSessionHTTPBodyType {
    case json
    case getString
}

open class NetworkRequest {
    open var method: NetworkRequestHTTPMethod = .GET
    open var url: URL
    open var urlParams: [AnyHashable: Any]?
    open var bodyJson: [AnyHashable: Any]?
    open var bodyData: Data?
    open var bodyType: NetworkSessionHTTPBodyType
    open var headers: [AnyHashable: Any]?
    open var shouldConvertSuccessResultToJSON: Bool
    open var networkRequestAuthProvider: NetworkRequestAuthProvider?

    open var shouldEncodeUrlParams: Bool

    public init(url: URL) {
        self.url = url
        bodyType = .json
        shouldConvertSuccessResultToJSON = true
        shouldEncodeUrlParams = true
    }

    // MARK: - request

    func urlRequest() -> URLRequest {
        var body: Data?
        if let bodyJson = bodyJson {
            switch bodyType {
            case .json:
                body = try? JSONSerialization.data(withJSONObject: bodyJson,
                                                   options: JSONSerialization.WritingOptions.prettyPrinted)
            case .getString:
                var components: [String] = []

                for objects in queryItems(dictionary: bodyJson) {
                    if let value = objects.value {
                        components.append("\(objects.name)=\(String(describing: value))")
                    }
                }

                body = components.joined(separator: "&").data(using: String.Encoding.utf8)
            }

        } else if let bodyData = bodyData {
            body = bodyData
        }

        return urlRequest(HTTPMethod: method.rawValue,
                          url: url,
                          urlParams: urlParams,
                          httpBody: body,
                          httpHeaders: headers)
    }

    // MARK: - request

    func urlRequest(HTTPMethod: String,
                    url: URL,
                    urlParams: [AnyHashable: Any]?,
                    httpBody: Data?,
                    httpHeaders: [AnyHashable: Any]?) -> URLRequest {
        var request: URLRequest

        if shouldEncodeUrlParams {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)

            if let parameters = urlParams {
                urlComponents?.queryItems = queryItems(dictionary: parameters)
            }
            guard let url = urlComponents?.url else { fatalError() }

            request = URLRequest(url: url)
        } else {
            var urlPath = url.absoluteString
            if let urlParams = urlParams {
                let params: String = urlParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
                if params.isEmpty == false {
                    urlPath += "?\(params)"
                }
            }
            guard let url = URL(string: urlPath) else { fatalError() }
            request = URLRequest(url: url)
        }

        request.httpMethod = HTTPMethod
        request.httpBody = httpBody

        if let headers = httpHeaders {
            for (key, value) in headers {
                request.setValue("\(value)", forHTTPHeaderField: "\(key)")
            }
        }

        return request
    }

    func queryItems(dictionary: [AnyHashable: Any]) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        for (key, value) in dictionary {
            items.append(URLQueryItem(name: "\(key)", value: "\(value)"))
        }
        return items
    }
}
