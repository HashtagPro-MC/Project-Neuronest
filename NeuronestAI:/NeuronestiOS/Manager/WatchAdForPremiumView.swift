//
//  WatchAdForPremiumView.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 1/2/26.
//


import SwiftUI

struct WatchAdForPremiumView: View {
    @EnvironmentObject var premium: PremiumStore
    @StateObject private var ads = RewardedAdManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            if premium.isPremium {
                Text("✅ Premium Active")
                    .font(.headline)

                if let until = premium.premiumUntil {
                    Text("Until: \(until.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Get 3-Day Premium")
                    .font(.headline)
                Text("Watch ads until 100 seconds total (by completions).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ProgressView(value: premium.progress01)
                Text("Remaining: \(premium.remainingSeconds)s")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    guard let root = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                        .first?.rootViewController else { return }

                    ads.show(from: root, premium: premium)
                } label: {
                    HStack {
                        if ads.isLoading { ProgressView() }
                        Text("Watch Ad (+25s)")
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(.blue.opacity(0.85)))
                    .foregroundStyle(.white)
                }
                .disabled(ads.isLoading)
            }

            if let e = ads.lastError {
                Text(e).font(.footnote).foregroundStyle(.red)
            }
        }
        .onAppear { ads.load() }
        .padding()
    }
}
