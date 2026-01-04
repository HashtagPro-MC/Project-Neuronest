//
//  GoogleSignInButtonView.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//


import SwiftUI
import GoogleSignInSwift

struct GoogleSignInButtonView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 10) {
            GoogleSignInButton {
                Task {
                    do {
                        try await auth.signInWithGoogle()
                        errorText = nil
                    } catch {
                        errorText = error.localizedDescription
                    }
                }
            }
            .frame(height: 50)

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}