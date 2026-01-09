import SwiftUI

struct HomeView: View {
    @EnvironmentObject var theme: ThemeStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        profileCard

                        sectionTitle("Quick Actions")
                        quickRow

                        sectionTitle("Your Tools")
                        toolGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 90) // leave space for sticky banner
                }

                // Sticky Ad Banner
                AdBannerView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
                    .frame(width: 320, height: 50)
                    .padding(.bottom, 10)
            }
        }
    }
    //

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Text("🧠").font(.system(size: 26))
            Text("Neuronest")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.primary)

            Spacer()

            Button { theme.toggle() } label: {
                Image(systemName: theme.isDark ? "sun.max.fill" : "moon.stars.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.primary.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        NavigationLink {
            ProfileSettingsView()
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 64, height: 64)
                    .overlay(Text("🙂").font(.system(size: 28)))

                VStack(alignment: .leading, spacing: 6) {
                    Text("My Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Settings • Schedule • Account")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary.opacity(0.8))
            }
            .padding(14)
            .background(cardBG)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Row

    private var quickRow: some View {
        HStack(spacing: 12) {
            NavigationLink { ChatListView() } label: {
                miniCard(emoji: "💬", title: "Chats")
            }
            NavigationLink { MatchingCardsView() } label: {
                miniCard(emoji: "🃏", title: "Matching")
            }
            NavigationLink { CognitiveReportView() } label: {
                miniCard(emoji: "📊", title: "Report")
            }
        }
    }

    // MARK: - Grid

    private var toolGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            tile(emoji: "🔎", title: "Search with AI", subtitle: "Sources & context") {
                AISearchView()
            }

            tile(emoji: "📅", title: "Schedule", subtitle: "Plan & reminders") {
                NeuronestCalendarView()
            }

            tile(emoji: "🥗", title: "Diet Planner", subtitle: "Brain-friendly meals") {
                DietPlannerView()
            }

            tile(emoji: "⚡️", title: "Focus Dash", subtitle: "Reaction & focus") {
                FocusDashView()
            }

          //tile(emoji: "🧩", title: "Memory Game", subtitle: "Train recall") {
          //     MemoryGameView()
          //  }

            //tile(emoji: "✏️", title: "Letter Fading", subtitle: "Attention drill") {
             //   LetterFadingView()
           //}
            tile(emoji: "🔢", title: "Number Memory", subtitle: "Digit span") {
                NumberMemoryView()
            }

            tile(emoji: "🛰️", title: "ESP32 BLE", subtitle: "Live device data") {
                BLESerialView()
            }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.top, 6)
    }

    private func miniCard(emoji: String, title: String) -> some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 22))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.90))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(cardBG)
    }

    private func tile<Destination: View>(
        emoji: String,
        title: String,
        subtitle: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 10) {
                Text(emoji)
                    .font(.system(size: 24))

                Text(title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBG)
        }
        .buttonStyle(.plain)
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.primary.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - Placeholder

struct PlaceholderView: View {
    let title: String
    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.title2.bold())
            Text("Coming soon…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        
        
    }
}
