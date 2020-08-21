// Generated using Sourcery 0.18.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Mirage2 
import PromiseKit

class MockPromisedRepositoryFRC: PromisedRepositoryFRC {
    //MARK: - VARIABLES
    //MARK: predicate
    lazy var mock_predicate_get = FuncCallHandler<Void, (NSPredicate?)>(returnValue: anyNSPredicateOpt())
    lazy var mock_predicate_set = FuncCallHandler<NSPredicate?, Void>(returnValue: ())
    var predicate: NSPredicate? {
        get { return mock_predicate_get.handle(()) }
        set(value) { mock_predicate_set.handle(value) }
    }

    //MARK: delegate
    lazy var mock_delegate_get = FuncCallHandler<Void, (PromisedRepositoryFRCDelegate?)>(returnValue: anyPromisedRepositoryFRCDelegateOpt())
    lazy var mock_delegate_set = FuncCallHandler<PromisedRepositoryFRCDelegate?, Void>(returnValue: ())
    var delegate: PromisedRepositoryFRCDelegate? {
        get { return mock_delegate_get.handle(()) }
        set(value) { mock_delegate_set.handle(value) }
    }

    //MARK: - FUNCTIONS
    //MARK: objects
    lazy var mock_objects = FuncCallHandler<Void, Guarantee<[Any]>>(returnValue: anyGuaranteeOfArrayOfAny())    
    func objects() -> Guarantee<[Any]> {
        return mock_objects.handle(())
    }
}
