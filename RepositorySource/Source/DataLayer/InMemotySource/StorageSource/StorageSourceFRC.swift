import Foundation
import PromiseKit

extension NSNotification.Name {
    static let DidUpdateStorage = Notification.Name("Storage.DidUpdateStorage")
}

open class StorageSourceFRC<T: Storable>: NSObject {
    fileprivate var storage: Storage
    fileprivate var request: StorageSourceRequest<T>
    fileprivate var notificationCenter: NotificationCenter
    fileprivate var cachedObjects: [T]

    fileprivate var queue: DispatchQueue

    public init(storage: Storage,
                request: StorageSourceRequest<T>,
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
            guard let objects = result as? [T],
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

            let predicate = __self.request.predicate

            __self.storage.fetch(predicate: predicate ?? { _ in true })
                .done { objects in
                    seal(objects)
                }
                .catch { _ in
                    seal([])
                }
        })
    }
}
