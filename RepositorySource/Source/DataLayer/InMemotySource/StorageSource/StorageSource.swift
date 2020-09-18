import Foundation
import PromiseKit

/**
 *  Protocol for InMemory Storage
 */
public protocol StorageSource {
    // MARK: fetch

    /// Give a promise to fetch data from Storage.
    ///
    /// - Parameter request:
    /// - Returns: a promise to be fulfilled
    func fetchData<T: Storable>(_ request: StorageSourceRequest<T>) -> Promise<[T]>

    /// Makes Storage frc
    ///
    /// - Parameter request:
    /// - Returns: Storage frc
    func makeFrc<T>(_ request: StorageSourceRequest<T>) -> StorageSourceFRC<T>

    // MARK: delete

    /// Give a promise to delete objects
    ///
    /// - Parameter request:
    /// - Returns: a promise to finish operation
    func delete<T: Storable>(_ request: StorageSourceRequest<T>) -> Promise<Void>

    // MARK: save

    /// Give a promise to insert or update objects
    ///
    /// - Parameter request:
    /// - Returns: a promise to finish operation
    func insertOrUpdate<T: Storable>(_ objects: [T]) -> Promise<Void>

    // MARK: import

    /// Give a promise to import data from json into storage
    ///
    /// - Parameters:
    ///   - json:
    ///   - mappingJsonToStorage:
    /// - Returns: a promise to finish operation
    func importJSON<T: Storable>(_ json: Any,
                                 mappingJsonToStorage: StorageMapping<T>) -> Promise<Void>
}
