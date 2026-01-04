//
//  ThemeStore.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//


import SwiftUI
import Combine

@MainActor
final class ThemeStore: ObservableObject {
    @Published var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "NN_isDark") }
    }

    init() {
        if UserDefaults.standard.object(forKey: "NN_isDark") != nil {
            self.isDark = UserDefaults.standard.bool(forKey: "NN_isDark")
        } else {
            self.isDark = true // 기본 다크
        }
    }

    func toggle() { isDark.toggle() }
}
