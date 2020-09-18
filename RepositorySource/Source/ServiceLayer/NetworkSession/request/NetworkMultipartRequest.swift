import Foundation

open class NetworkMultipartRequest: NetworkRequest {
    open var imagesData: [Data] = []

    override func urlRequest() -> URLRequest {
        multipartUrlRequest(url: url, urlParams: urlParams, imagesData: imagesData, httpHeaders: headers)
    }

    func multipartUrlRequest(url: URL,
                             urlParams _: [AnyHashable: Any]?,
                             imagesData: [Data],
                             httpHeaders: [AnyHashable: Any]?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary: String = "unique-consistent-string"

        // set Content-Type in HTTP header
        let contentType: String = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        // post body
        var body = Data()

        // swiftlint:disable force_unwrapping
        // swiftlint:disable line_length
        // add image data
        for image in imagesData {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition: form-data; name=\("imageFormKey"); filename=imageName.jpg\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append(image)
            body.append("\r\n".data(using: String.Encoding.utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)

        // setting the body of the post to the reqeust
        request.httpBody = body

        // set the content-length
        let postLength: String = "\(UInt(body.count))"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")

        if let headers = httpHeaders {
            for (key, value) in headers {
                request.setValue("\(value)", forHTTPHeaderField: "\(key)")
            }
        }

        return request
    }
}
