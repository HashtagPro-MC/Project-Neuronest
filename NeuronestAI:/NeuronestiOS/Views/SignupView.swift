import SwiftUI

struct SignupView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var errorMessage: String? = nil

    /// Optional callback used by AuthGlassShellView / AuthEntryView.
    let onSwitchToLogin: (() -> Void)?

    init(onSwitchToLogin: (() -> Void)? = nil) {
        self.onSwitchToLogin = onSwitchToLogin
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Create Account")
                        .font(.system(size: 18, weight: .bold))

                    TextField("Email or Username", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.18)))

                    SecureField("Password", text: $password)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.18)))

                    SecureField("Confirm Password", text: $confirm)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.18)))
                }
                .padding(.horizontal, 22)

                if let e = errorMessage {
                    Text(e).foregroundStyle(.red).font(.footnote)
                }

                HStack {
                    Spacer()
                    Button {
                        if email.isEmpty || password.isEmpty {
                            errorMessage = "필수 항목을 입력해줘."
                            return
                        }
                        if password != confirm {
                            errorMessage = "비밀번호가 일치하지 않아."
                            return
                        }
                        errorMessage = nil
                        // Mark onboarding as completed with the simplified AuthViewModel
                        auth.didFinishGetStarted = true
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Color.blue))
                    }
                    .padding(.trailing, 22)
                }

                // ✅ Storyboard 섹션
                VStack(alignment: .leading, spacing: 10) {
                    Text("Storyboard")
                        .font(.system(size: 16, weight: .bold))

                    Text("""
Neuronest was conceived as a mobile application aimed at preventing Alzheimer’s disease and mild cognitive impairment by combining cognitive enhancement games that train memory, attention, and reaction speed with AI-based analysis. In its early stages, the app was developed on Android with consideration for potential hardware integration such as heart rate sensors and vibration motors, while core cognitive training logic and user response data collection and processing were designed in Kotlin. Using Compose UI and AI API integration, the app implemented key features including personalized analysis of training records and customized feedback. To expand across platforms, Kotlin Multiplatform (KMM) was experimentally adopted and successfully validated through shared logic between Android and iOS and execution on the iOS simulator. However, prioritizing native performance and user experience, the development strategy ultimately shifted away from KMP toward creating a dedicated iOS project using SwiftUI. At present, the core concepts and logic of Neuronest—such as cognitive training rules, AI integration structure, and data processing flow—have been reimplemented using Swift and async/await, reaching a stage where a fully native and extensible Neuronest iOS version can run in a macOS development environment.
""")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.10)))
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                Button {
                    onSwitchToLogin?()
                } label: {
                    Text("Already member?  Swipe down / Login")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
            }
        }
    }
}
