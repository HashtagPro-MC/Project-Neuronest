import SwiftUI

struct GetStartedView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.92), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer()

                    VStack(spacing: 12) {
                        Text("Neuronest")
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(.white)

                        Text("Train focus • memory • habits\nNo medical diagnosis. \n Just for the People.🧠")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    NavigationLink {
                        AuthGlassShellView()   // ✅ 여기로 이동
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.14))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 28)
                }
            }
        }
    }
}

#Preview {
    GetStartedView()
}
