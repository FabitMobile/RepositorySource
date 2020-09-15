import CoreData
import Foundation
import PromiseKit
import UIKit

class SaveOperation: Operation {
    enum State: String {
        case isReady
        case isExecuting
        case isFinished
    }
    
    // MARK: - props
    var state: State = .isReady {
        willSet(newValue) {
            willChangeValue(forKey: state.rawValue)
            willChangeValue(forKey: newValue.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }
    var lastError: Error?
    
    var saveQueue: DispatchQueue
    
    // MARK: - DI
    var coreDataService: CoreDataService
    var notificationCenter: NotificationCenter
    var block: PromisedCoreDataSourceActionBlock
    
    override var isAsynchronous: Bool { true }
    override var isExecuting: Bool { state == .isExecuting }
    override var isFinished: Bool {
        if isCancelled && state != .isExecuting { return true }
        return state == .isFinished
    }
    
    init(coreDataService: CoreDataService,
         notificationCenter: NotificationCenter,
         _ block: @escaping PromisedCoreDataSourceActionBlock) {
        self.coreDataService = coreDataService
        self.notificationCenter = notificationCenter
        self.block = block
        self.saveQueue = DispatchQueue(label: "SaveOperation.saveQueue",
                                       qos: .userInteractive)
        
        super.init()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
}

extension SaveOperation {
    override func start() {
        guard !isCancelled else { return }
        state = .isExecuting
        
        DispatchQueue.main.async { [weak self] in
            guard let __self = self else { return }
            if UIApplication.shared.isProtectedDataAvailable {
                __self.saveAsync()
            } else {
                let selector = #selector(__self.handleProtectedDataDidBecomeAvailableNotification)
                __self.notificationCenter.addObserver(__self,
                                                      selector: selector,
                                                      name: UIApplication.protectedDataDidBecomeAvailableNotification,
                                                      object: nil)
            }
        }
        
        
    }
    
    @objc
    func handleProtectedDataDidBecomeAvailableNotification() {
        saveAsync()
    }
    
    public func saveAsync() {
        saveQueue.async { [weak self] in
            guard let __self = self else { return }
            let ctx = __self.coreDataService.makeBackgroundContext()
            
            ctx.performAndWait { [weak self] in
                guard let __self = self else { return }
                do {
                   
                    try __self.block(ctx)
                    try __self.coreDataService.saveContext(ctx)
                    __self.completionBlock?()
                    __self.state = .isFinished
                } catch {
                    __self.lastError = error
                    __self.completionBlock?()
                    __self.state = .isFinished
                }
            }
        }
        
    }
}
