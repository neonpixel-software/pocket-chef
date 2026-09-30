import Foundation

protocol ICloudAccountStatusProvider: Sendable {
    func status() async -> ICloudAccountStatus
}
