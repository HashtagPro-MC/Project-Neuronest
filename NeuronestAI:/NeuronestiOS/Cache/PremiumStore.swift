//
//  PremiumStore.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 1/2/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class PremiumStore: ObservableObject {
    // 100초 채우면 3일 프리미엄
    private let targetSeconds: Int = 100
    private let grantDays: Int = 3

    @AppStorage("premium_until_ts") private var premiumUntilTs: Double = 0
    @AppStorage("ad_watch_seconds") private var watchedSeconds: Int = 0

    var isPremium: Bool {
        Date().timeIntervalSince1970 < premiumUntilTs
    }

    var premiumUntil: Date? {
        premiumUntilTs > 0 ? Date(timeIntervalSince1970: premiumUntilTs) : nil
    }

    var progressSeconds: Int { min(watchedSeconds, targetSeconds) }
    var remainingSeconds: Int { max(0, targetSeconds - watchedSeconds) }
    var progress01: Double { Double(progressSeconds) / Double(targetSeconds) }

    func addWatchCredit(seconds: Int) {
        // 프리미엄이면 굳이 누적 안 해도 됨 (원하면 누적 계속해도 됨)
        if isPremium { return }

        watchedSeconds += seconds

        if watchedSeconds >= targetSeconds {
            // 3일 프리미엄 부여
            let until = Calendar.current.date(byAdding: .day, value: grantDays, to: Date()) ?? Date().addingTimeInterval(3*86400)
            premiumUntilTs = until.timeIntervalSince1970

            // 다음번을 위해 누적 초기화(원하면 남은 초 이월도 가능)
            watchedSeconds = 0
        }
    }

    func resetProgress() {
        watchedSeconds = 0
    }

    func clearPremium() {
        premiumUntilTs = 0
        watchedSeconds = 0
    }
}
