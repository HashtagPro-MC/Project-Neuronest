import Foundation
import LocalAuthentication

enum LocalAuthError: Error, LocalizedError {
    case notAvailable
    case failed

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "이 기기에서 Face ID/Touch ID를 사용할 수 없어."
        case .failed: return "인증 실패. 다시 시도해줘."
        }
    }
}

final class LocalAuthService {

    func authenticate(reason: String = "Neuronest 로그인") async throws -> Bool {
        let context = LAContext()
        var err: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            // biometrics 없으면 passcode도 허용하고 싶으면 아래로 바꾸면 됨:
            // return try await authenticateWithPasscodeFallback(reason: reason)
            throw LocalAuthError.notAvailable
        }

        return try await withCheckedThrowingContinuation { cont in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: reason) { success, _ in
                if success { cont.resume(returning: true) }
                else { cont.resume(throwing: LocalAuthError.failed) }
            }
        }
    }

    // (선택) FaceID 없을 때 암호로도 허용하고 싶으면 사용:
    func authenticateWithPasscodeFallback(reason: String = "Neuronest 로그인") async throws -> Bool {
        let context = LAContext()
        var err: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            throw LocalAuthError.notAvailable
        }

        return try await withCheckedThrowingContinuation { cont in
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                   localizedReason: reason) { success, _ in
                if success { cont.resume(returning: true) }
                else { cont.resume(throwing: LocalAuthError.failed) }
            }
        }
    }
}
