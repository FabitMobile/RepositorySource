import Foundation

open class BaseJsonTransformer {
    public init() {}

    /// Transforms part of given json according to overriden method transformedJsonObject
    ///
    /// - Parameters:
    ///   - json: original json (url request response)
    ///   - keyPath: keypath to the part of json which should be transformed
    open func transformedJson(_ json: Any, keyPath: String?, userInfo: Any?) -> Any {
        // get
        var jsonToFix: Any
        if let keyPath = keyPath,
            let jsonDictionary = json as? [AnyHashable: Any],
            let object = jsonDictionary[keyPath] {
            jsonToFix = object
        } else {
            jsonToFix = json
        }

        //  modify
        jsonToFix = transformedJson(jsonToFix, userInfo: userInfo)

        //  set
        if let keyPath = keyPath, var fixedJsonDictionary = json as? [AnyHashable: Any] {
            fixedJsonDictionary[keyPath] = jsonToFix
            return fixedJsonDictionary

        } else {
            return jsonToFix
        }
    }

    // MARK: base method

    fileprivate func transformedJson(_ json: Any, userInfo: Any?) -> Any {
        if let json = json as? [[AnyHashable: Any]] {
            return transformedJsonArray(json, userInfo: userInfo)

        } else if let json = json as? [AnyHashable: Any] {
            return transformedJsonObject(json, userInfo: userInfo)

        } else {
            return json
        }
    }

    open func transformedJsonArray(_ json: [[AnyHashable: Any]], userInfo: Any?) -> [[AnyHashable: Any]] {
        var result: [[AnyHashable: Any]] = []
        for object in json {
            result.append(transformedJsonObject(object, userInfo: userInfo))
        }
        return result
    }

    /// Should be overriden in subclass and should never be called direclty
    ///
    /// - Parameter json: original json (url request response)
    /// - Returns: transformed json
    open func transformedJsonObject(_ json: [AnyHashable: Any], userInfo _: Any?) -> [AnyHashable: Any] {
        json
    }
}
