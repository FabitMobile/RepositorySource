import Foundation
import PromiseKit

public protocol PromisedRepositoryFRCDelegate: AnyObject {
    func frc(_ frc: PromisedRepositoryFRC, didUpdateObjects objects: [Any])
}

// sourcery: mirageMock
public protocol PromisedRepositoryFRC: AnyObject {
    var predicate: NSPredicate? { get set }

    var delegate: PromisedRepositoryFRCDelegate? { get set }

    func objects() -> Guarantee<[Any]>
}
