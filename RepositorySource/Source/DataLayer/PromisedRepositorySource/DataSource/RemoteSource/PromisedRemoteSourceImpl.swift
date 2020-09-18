import Foundation
import PromiseKit

class PromisedRemoteSourceNoImportInfoError: Error {}
class PromisedRemoteSourceNoJsonError: Error {}

public class PromisedRemoteSourceImpl {
    var remoteService: RemoteService

    public init(remoteService: RemoteService) {
        self.remoteService = remoteService
    }

    typealias RSourceTuple = (PromisedRemoteSourceRequest, RemoteServiceResponse)
}

// swiftlint:disable line_length
extension PromisedRemoteSourceImpl: PromisedRemoteSource {
    public func execute(_ request: PromisedRemoteSourceRequest) -> Promise<PromisedRemoteSourceResponse> {
        let qUserInitiated = DispatchQueue.global(qos: .userInitiated)
        return getRemoteResponse(request)
            .then(on: qUserInitiated) { [weak self] (tuple) -> Promise<PromisedRemoteSourceResponse> in
                let request = tuple.0
                let response = tuple.1

                guard let error = response.error else {
                    return Promise.value(tuple)
                        .then(on: qUserInitiated) { [weak self] (tuple) -> Promise<(RSourceTuple, [Any]?)> in
                            guard let __self = self else { throw NilSelfError() }
                            return __self.importJSON(tuple.0, tuple.1)
                        }
                        .then { [weak self] (tuple: RSourceTuple, ids: [Any]?) -> Promise<PromisedRemoteSourceResponse> in
                            guard let __self = self else { throw NilSelfError() }
                            return __self.mapResponse(tuple.0, tuple.1, ids)
                        }
                }

                let handlings: [Promise<PromisedRemoteSourceErrorHandlerResponse>] = request
                    .errorHandlers
                    .map { handler in
                        handler.handle(error: error, from: request)
                    }
                return when(fulfilled: handlings)
                    .then { [weak self] (results) -> Promise<PromisedRemoteSourceResponse> in
                        guard let __self = self else { throw NilSelfError() }

                        guard let result = results.first(where: { $0.shouldRetryRequest == true }) else {
                            return Promise(error: error)
                        }

                        if let headers = result.newHeaders {
                            request.networkRequest.headers = headers
                        }
                        return __self.execute(request)
                    }
            }
    }
}

extension PromisedRemoteSourceImpl {
    func getRemoteResponse(_ request: PromisedRemoteSourceRequest) -> Promise<RSourceTuple> {
        let relativePath = request.networkRequest.url.absoluteString
        guard let url = URL(string: relativePath, relativeTo: remoteService.baseURL) else { fatalError() }
        request.networkRequest.url = url
        return remoteService.execute(request.networkRequest)
            .map { (request, $0) }
    }

    func importJSON(_ request: PromisedRemoteSourceRequest,
                    _ response: RemoteServiceResponse) -> Promise<(RSourceTuple, [Any]?)> {
        Promise(resolver: { seal in
            guard request.networkRequest.shouldConvertSuccessResultToJSON, response.httpStatus != 204 else {
                seal.fulfill(((request, response), nil))
                return
            }

            guard var json = response.json else {
                seal.reject(PromisedRemoteSourceNoJsonError())
                return
            }

            guard let importInfo = request.importInfo else {
                seal.fulfill(((request, response), nil))
                return
            }

            let localSourceForImport = importInfo.localSourceForImport
            let mappingJsonToDb = importInfo.mappingJsonToDb

            //  transfrom json
            if let beforeImportBlock = importInfo.beforeImportBlock {
                json = beforeImportBlock(json)
            }
            if let jsonKeyPath = importInfo.jsonKeyPath,
                let jsonDict = json as? NSDictionary {
                json = jsonDict.value(forKeyPath: jsonKeyPath) as Any
            }

            //  import
            _ = try localSourceForImport.importJSON(json,
                                                    mappingJsonToDb: mappingJsonToDb).wait()

            var loadedIdentifiers: [Any] = []

            if let primaryKey = mappingJsonToDb.primaryKey,
                let primaryKeyMappingBlock = mappingJsonToDb.attributes.first(where: { $0.property == primaryKey }) {
                if let jsonArray = json as? [[String: Any]] {
                    loadedIdentifiers.append(contentsOf: jsonArray.compactMap { $0[primaryKeyMappingBlock.keyPath] })

                } else if let jsonDict = json as? [String: Any],
                    let value = jsonDict[primaryKeyMappingBlock.keyPath] {
                    loadedIdentifiers.append(value)
                }
            }

            seal.fulfill(((request, response), loadedIdentifiers))
        })
    }

    func mapResponse(_ request: PromisedRemoteSourceRequest,
                     _ response: RemoteServiceResponse,
                     _ loadedIdentifiers: [Any]?) -> Promise<PromisedRemoteSourceResponse> {
        Promise(resolver: { seal in
            let sourceResponse = PromisedRemoteSourceResponse(httpStatus: response.httpStatus,
                                                              data: response.data,
                                                              json: response.json,
                                                              loadedIdentifiers: loadedIdentifiers)
            seal.fulfill(sourceResponse)
        })
    }
}
