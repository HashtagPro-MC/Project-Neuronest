import SwiftUI

struct HomeCard: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 34))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(radius: 8, y: 4)
    }
}
