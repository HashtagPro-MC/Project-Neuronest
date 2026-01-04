import SwiftUI

struct MatchingCardsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var analytics: AnalyticsStore
    @StateObject private var vm = MatchingCardsViewModel()
    @State private var didSaveSession = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 10) {
            header

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(vm.cards) { card in
                    CardCell(card: card) {
                        vm.tap(card)
                    }
                }
            }
            .padding(16)

            footer
        }
        .navigationBarBackButtonHidden(true)
        .background(Color(.systemBackground))
        .onAppear { /* timer starts in reset() */ }
        .onDisappear { vm.stopTimer() }
        .onChange(of: vm.isFinished) { _, newValue in
            if newValue {
                saveIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("🃏 Matching Cards")
                    .font(.headline)
                Text("Moves \(vm.moves) · Time \(vm.elapsed)s")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                vm.reset()
            } label: {
                Text("Reset")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                StatPill(text: "✅ \(vm.correctMatches)")
                StatPill(text: "❌ \(vm.wrongMatches)")
                let total = max(1, vm.correctMatches + vm.wrongMatches)
                let acc = Int((Double(vm.correctMatches) / Double(total) * 100).rounded())
                StatPill(text: "🎯 \(acc)%")
            }

            Button {
                vm.finishGame()
                saveIfNeeded()
            } label: {
                Text("End Game & Save to Report")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.blue.opacity(0.9)))
                    .foregroundColor(.white)
            }

            if vm.isFinished {
                Text("🎉 Completed! Saved to Report")
                    .font(.subheadline.bold())
                    .padding(.top, 2)
            }
        }
        .padding(.bottom, 14)
    }

    @MainActor
    private func saveIfNeeded() {
        guard !didSaveSession else { return }
        // Only save if user actually played a bit.
        let playedAny = (vm.correctMatches + vm.wrongMatches) > 0 || vm.moves > 0
        guard playedAny else { return }

        analytics.addSession(vm.buildSession())
        didSaveSession = true
    }
}

private struct StatPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
    }
}

private struct CardCell: View {
    let card: MemoryCard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(card.isFaceUp || card.isMatched ? Color(.secondarySystemBackground) : Color(.label))
                    .shadow(radius: 2, y: 2)

                if card.isFaceUp || card.isMatched {
                    Text(card.emoji)
                        .font(.system(size: 30))
                        .transition(.scale)
                } else {
                    Text("❓")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(height: 72)
        }
        .buttonStyle(.plain)
        .disabled(card.isMatched)
    }
}
