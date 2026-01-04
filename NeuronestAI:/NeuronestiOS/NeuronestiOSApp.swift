// NeuronestiOSApp.swift
import SwiftUI
import GoogleSignIn

@main
struct NeuronestiOSApp: App {
    // AppDelegate가 없어서 에러 나면 이 줄 + 아래 AppDelegate 클래스를 같이 두면 됨
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var auth = AuthViewModel()
    @StateObject private var chatStore = ChatStore()
    @StateObject private var analytics = AnalyticsStore()
    @StateObject private var calendarService = CalendarService()
    @StateObject private var noti = NotificationManager()
    @StateObject private var theme = ThemeStore()

    init() {
        // ✅ Info.plist에 GIDClientID가 있으면 그걸로 설정 (하드코딩 X)
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(chatStore)
                .environmentObject(analytics)
                .environmentObject(calendarService)
                .environmentObject(noti)
                .environmentObject(theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

