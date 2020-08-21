import Foundation
import PromiseKit

public typealias PromisedCoreDataSourceActionBlock = (_ context: PromisedCoreDataSourceContext) throws -> Void

public protocol PromisedCoreDataSourceContext {}

/**
 *  Protocol for core data storage
 */
public protocol PromisedCoreDataSource {
    // MARK: fetch

    /// Give a promise to fetch data from CoreData.
    ///
    /// - Parameter request:
    /// - Returns: a promise to be fulfilled
    func fetchData<T>(_ request: PromisedCoreDataSourceRequest) -> Guarantee<[T]>

    /// Fetch data from CoreData in a specific context
    ///
    /// - Parameters:
    ///   - request:
    ///   - context:
    /// - Returns: domain objects if given mapping else data objects
    func fetchData<T>(_ request: PromisedCoreDataSourceRequest,
                      inContext context: PromisedCoreDataSourceContext) -> [T]

    /// Give a promise to count number of objects for a given fetch request.
    ///
    /// - Parameter request:
    /// - Returns: number of objects
    func count(_ request: PromisedCoreDataSourceRequest) -> Guarantee<Int>

    /// Counts number of objects for a given fetch request.
    ///
    /// - Parameters:
    ///   - request:
    ///   - context:
    /// - Returns: number of objects
    func count(_ request: PromisedCoreDataSourceRequest,
               inContext context: PromisedCoreDataSourceContext) -> Int

    /// Makes CoreData frc
    ///
    /// - Parameter request:
    /// - Returns: CoreData frc
    func makeFrc(_ request: PromisedCoreDataSourceRequest) -> PromisedRepositoryFRC

    // MARK: save

    /// Save storage asynchronously
    ///
    /// - Parameter block: actions to modify storage
    /// - Returns: a promise to finish operation
    func saveAsync(_ block: @escaping PromisedCoreDataSourceActionBlock) -> Promise<Bool>

    // MARK: delete

    /// Give a promise to delete objects
    ///
    /// - Parameter request:
    /// - Returns: a promise to finish operation
    func deleteAsync(_ request: PromisedCoreDataSourceRequest) -> Promise<Bool>

    /// Delete objects using predicate in a specific context
    ///
    /// - Parameters:
    ///   - request:
    ///   - context:
    /// - Returns:
    func delete(_ request: PromisedCoreDataSourceRequest,
                inContext context: PromisedCoreDataSourceContext)

    // MARK: import

    /// Give a promise to import data from json into db
    ///
    /// - Parameters:
    ///   - json:
    ///   - mappingJsonToDb:
    /// - Returns: a promise to finish operation
    func importJSON(_ json: Any,
                    mappingJsonToDb: Mapping) -> Promise<Bool>
}
