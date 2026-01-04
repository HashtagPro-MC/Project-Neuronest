import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil

    @State private var isLoadingGoogle = false
    @State private var isLoadingBio = false

    let onSwitchToSignup: (() -> Void)?

    init(onSwitchToSignup: (() -> Void)? = nil) {
        self.onSwitchToSignup = onSwitchToSignup
    }

    var body: some View {
        VStack(spacing: 14) {

            VStack(alignment: .leading, spacing: 10) {
                Text("Login")
                    .font(.system(size: 18, weight: .bold))

                TextField("Email or Username", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.18)))

                SecureField("Password", text: $password)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.18)))
            }
            .padding(.horizontal, 22)

            if let e = errorMessage {
                Text(e)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal, 22)
            }

            // Email Login (demo)
            HStack {
                Spacer()
                Button {
                    if email.isEmpty || password.isEmpty {
                        errorMessage = "이메일/비번 입력해줘."
                        return
                    }
                    errorMessage = nil
                    auth.userName = email
                    auth.isLoggedIn = true
                    auth.didFinishGetStarted = true
                    dismiss()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(Color.blue))
                }
                .padding(.trailing, 22)
            }

            VStack(spacing: 10) {

                // ✅ Face ID 버튼
                Button {
                    Task { await faceIdSignIn() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 18, weight: .bold))
                        Text(isLoadingBio ? "Unlocking..." : "Unlock with Face ID")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        if isLoadingBio { ProgressView().tint(.white) }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.75)))
                    .foregroundStyle(.white)
                }
                .disabled(isLoadingBio)

                // ✅ Google 버튼 (그대로)
                Button {
                    Task { await googleSignIn() }
                } label: {
                    HStack(spacing: 10) {
                        Text("G")
                            .font(.system(size: 18, weight: .black))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.20)))

                        Text(isLoadingGoogle ? "Signing in..." : "Sign in with Google")
                            .font(.system(size: 15, weight: .bold))

                        Spacer()
                        if isLoadingGoogle { ProgressView().tint(.white) }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.85)))
                    .foregroundStyle(.white)
                }
                .disabled(isLoadingGoogle)

                Button { onSwitchToSignup?() } label: {
                    Text("New user?  Swipe up / Sign up")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 22)
        }
    }

    @MainActor
    private func googleSignIn() async {
        guard !isLoadingGoogle else { return }
        isLoadingGoogle = true
        defer { isLoadingGoogle = false }
        do {
            try await auth.signInWithGoogle()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func faceIdSignIn() async {
        guard !isLoadingBio else { return }
        isLoadingBio = true
        defer { isLoadingBio = false }
        do {
            try await auth.signInWithBiometrics()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
