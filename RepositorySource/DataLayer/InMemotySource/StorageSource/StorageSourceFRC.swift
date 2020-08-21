import Foundation
import PromiseKit

extension NSNotification.Name {
    static let DidUpdateStorage = Notification.Name("Storage.DidUpdateStorage")
}

open class StorageSourceFRC<T: Storable>: NSObject {
    fileprivate var storage: Storage
    fileprivate var request: StorageSourceRequest
    fileprivate var notificationCenter: NotificationCenter
    fileprivate var cachedObjects: [Storable]

    fileprivate var queue: DispatchQueue

    public init(storage: Storage,
                request: StorageSourceRequest,
                notificationCenter: NotificationCenter) {
        self.storage = storage
        self.request = request
        self.notificationCenter = notificationCenter

        queue = DispatchQueue(label: "StorageSourceFRC")
        cachedObjects = []

        super.init()

        notificationCenter.addObserver(self,
                                       selector: #selector(didUpdateStorage),
                                       name: Notification.Name.DidUpdateStorage,
                                       object: nil)
        didUpdateStorage()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc
    func didUpdateStorage() {
        queue.async { [weak self] in
            guard let __self = self,
                let delegate = __self.delegate else { return }

            let result = __self.objects().wait()
            guard let objects = result as? [Storable],
                objects != __self.cachedObjects else { return }

            __self.cachedObjects = objects

            delegate.frc(__self, didUpdateObjects: objects)
        }
    }

    // MARK: PromisedRepositoryFRC

    open weak var delegate: PromisedRepositoryFRCDelegate?
}

extension StorageSourceFRC: PromisedRepositoryFRC {
    open var predicate: NSPredicate? {
        get {
            preconditionFailure("does not support")
        }

        set {
            // swiftlint:disable:previous unused_setter_value
            preconditionFailure("does not support")
        }
    }

    public func objects() -> Guarantee<[Any]> {
        Guarantee(resolver: { [weak self] seal in
            guard let __self = self else { return }

            let predicate = __self.request.predicate ?? { _ in true }

            __self.storage.fetch(type: T.self, predicate: predicate)
                .done { objects in
                    seal(objects)
                }
                .catch { _ in
                    seal([])
                }
        })
    }
}
