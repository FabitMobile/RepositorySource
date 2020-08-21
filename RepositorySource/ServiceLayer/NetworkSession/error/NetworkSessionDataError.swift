import Foundation

open class NetworkSessionDataError: NetworkSessionError {
    public init() {
        super.init(domain: "", code: 42, userInfo: [:])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
