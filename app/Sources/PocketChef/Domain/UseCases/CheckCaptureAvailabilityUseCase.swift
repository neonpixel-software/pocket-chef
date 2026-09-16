import Foundation

protocol CheckCaptureAvailabilityUseCase {
    func execute() -> Bool
}

final class DefaultCheckCaptureAvailabilityUseCase: CheckCaptureAvailabilityUseCase {
    private let captureService: RecipeCaptureService

    init(captureService: RecipeCaptureService) {
        self.captureService = captureService
    }

    func execute() -> Bool {
        captureService.isAvailable()
    }
}
