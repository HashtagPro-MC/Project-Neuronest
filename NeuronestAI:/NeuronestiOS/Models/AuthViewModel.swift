import SwiftUI
import GoogleSignIn
import Combine
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isLoggedIn: Bool = false
    @Published var userName: String = ""

    // 라우팅 플래그 (GetStarted -> Auth/Home)
    @AppStorage("didFinishGetStarted") var didFinishGetStarted: Bool = false

    // FaceID를 “사용자 설정으로 활성화했는지”
    @AppStorage("faceIdEnabled") var faceIdEnabled: Bool = true

    func completeGetStarted() { didFinishGetStarted = true }
    func resetGetStarted() { didFinishGetStarted = false }

    func logout() {
        // Perform Google sign-out off the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            GIDSignIn.sharedInstance.signOut()
        }
        
        // Update app state on the main actor (this class is @MainActor)
        isLoggedIn = false
        userName = ""
        didFinishGetStarted = false
    }

    func signInWithGoogle() async throws {
        guard let rootVC = await UIApplication.shared.topMostViewController() else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        let profile = result.user.profile

        userName = profile?.name ?? "User"
        isLoggedIn = true
        didFinishGetStarted = true
    }

    /// ✅ Face ID / Touch ID 로그인
    func signInWithBiometrics() async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw NSError(domain: "Biometrics", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: error?.localizedDescription ?? "Biometrics not available"])
        }

        let ok = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock Neuronest with Face ID"
        )

        guard ok else {
            throw NSError(domain: "Biometrics", code: -2, userInfo: [NSLocalizedDescriptionKey: "Face ID failed"])
        }

        // 성공 처리
        userName = userName.isEmpty ? "User" : userName
        isLoggedIn = true
        didFinishGetStarted = true
    }
}

// MARK: - UIKit helper (GoogleSignIn에서 필요)
extension UIApplication {
    func topMostViewController() async -> UIViewController? {
        await MainActor.run {
            guard
                let scene = connectedScenes.first as? UIWindowScene,
                let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            else { return nil }

            var top = root
            while let presented = top.presentedViewController { top = presented }
            return top
        }
    }
}

