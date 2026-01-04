import SwiftUI
import Combine

struct AuthGlassShellView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var isSignup = false
    @State private var isSigningIn = false
    @State private var signInError: String? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.35), Color.purple.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .frame(maxWidth: 360)
                        .padding(.horizontal, 18)

                    VStack(spacing: 16) {
                        HStack {
                            Text(isSignup ? "Create Account" : "Hello!")
                                .font(.system(size: 26, weight: .heavy))
                            Spacer()
                            Button {
                                withAnimation(.spring()) { isSignup.toggle() }
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(10)
                                    .background(Circle().fill(Color.white.opacity(0.15)))
                            }
                        }
                        .padding(.top, 22)
                        .padding(.horizontal, 22)

                        if isSignup {
                            InlineSignupView(onSwitchToLogin: {
                                withAnimation(.spring()) { isSignup = false }
                            })
                            .padding(.horizontal, 22)
                        } else {
                            InlineLoginView(onSwitchToSignup: {
                                withAnimation(.spring()) { isSignup = true }
                            })
                            .padding(.horizontal, 22)
                        }

                        // Sign in with Google button
                        GoogleSignInButton {
                            isSigningIn = true
                            signInError = nil
                            GoogleSignInButton {
                                isSigningIn = true
                                signInError = nil

                                Task {
                                    do {
                                        try await auth.signInWithGoogle()
                                    } catch {
                                        signInError = error.localizedDescription
                                    }
                                    isSigningIn = false
                                }
                            }
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 22)
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 18)
                }

                Spacer()
            }
            
            if isSigningIn {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView("Signing in…")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
            }
            
            if let error = signInError {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule().fill(Color.red.opacity(0.9))
                        )
                        .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: signInError)
            }
        }
    }
// MARK: - Google Sign-In Button (Glass style)
struct GoogleSignInButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "g.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 20))
                Text("Sign in with Google")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Inline Login/Signup (lightweight stubs)
struct InlineLoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    var onSwitchToSignup: () -> Void
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome back")
                .font(.system(size: 18, weight: .heavy))

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))

            Button {
                // TODO: Call your AuthViewModel login(email,password)
            } label: {
                Text("Log In")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.85)))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            HStack {
                Spacer()
                Button(action: onSwitchToSignup) {
                    Text("Don't have an account? Sign up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
    }
}

struct InlineSignupView: View {
    @EnvironmentObject var auth: AuthViewModel
    var onSwitchToLogin: () -> Void
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create your account")
                .font(.system(size: 18, weight: .heavy))

            TextField("Name", text: $name)
                .textContentType(.name)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))

            Button {
                // TODO: Call your AuthViewModel signup(name,email,password)
            } label: {
                Text("Create Account")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple.opacity(0.85)))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            HStack {
                Spacer()
                Button(action: onSwitchToLogin) {
                    Text("Already have an account? Log in")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
    }
}

