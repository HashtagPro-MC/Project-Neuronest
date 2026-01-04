//
//  DailyQuotaStore.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//

import Combine
import Foundation

@MainActor
final class DailyQuotaStore: ObservableObject {
    @Published private(set) var used: Int = 0
    let limit: Int

    private let usedKey = "gemini_used"
    private let dayKey  = "gemini_day"

    init(limit: Int = 20) {
        self.limit = limit
        load()
    }

    func canUseAI() -> Bool {
        refreshIfNewDay()
        return used < limit
    }

    func markUsed() {
        refreshIfNewDay()
        used += 1
        save()
    }

    private func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func refreshIfNewDay() {
        let savedDay = UserDefaults.standard.string(forKey: dayKey) ?? ""
        let today = todayString()
        if savedDay != today {
            used = 0
            UserDefaults.standard.set(today, forKey: dayKey)
            UserDefaults.standard.set(0, forKey: usedKey)
        }
    }

    private func load() {
        refreshIfNewDay()
        used = UserDefaults.standard.integer(forKey: usedKey)
    }

    private func save() {
        UserDefaults.standard.set(used, forKey: usedKey)
        UserDefaults.standard.set(todayString(), forKey: dayKey)
    }
}
