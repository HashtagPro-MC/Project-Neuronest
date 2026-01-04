import SwiftUI

struct AuthEntryView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var showLogin = false
    @State private var showSignup = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                // ✅ TOP: Title
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 78, height: 78)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.purple)
                    }
                    .padding(.top, 36)

                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .heavy))

                    Text("Sign in to continue to your account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 18)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                // ✅ BOTTOM: Login / Sign Up bar (segmented/pill)
                VStack(spacing: 14) {
                    SegmentedAuthBar(
                        onLogin: { showLogin = true },
                        onSignup: { showSignup = true }
                    )
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
                .environmentObject(auth)
        }
    }
}

private struct SegmentedAuthBar: View {
    var onLogin: () -> Void
    var onSignup: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onLogin) {
                Text("Login")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onSignup) {
                Text("Sign Up")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(Color.primary)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
