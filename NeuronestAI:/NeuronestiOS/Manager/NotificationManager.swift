//
//  NotificationManager.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//


import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    enum NotiError: Error, LocalizedError {
        case denied
        case scheduleFailed(String)

        var errorDescription: String? {
            switch self {
            case .denied: return "알림 권한이 거부됨"
            case .scheduleFailed(let msg): return "알림 예약 실패: \(msg)"
            }
        }
    }

    private let center = UNUserNotificationCenter.current()

    func requestPermission() async throws {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !granted { throw NotiError.denied }
    }

    /// 매일 특정 시각 반복 알림
    func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        title: String,
        body: String,
        identifier: String = "neuronest.daily.reminder"
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateMatching = DateComponents()
        dateMatching.hour = hour
        dateMatching.minute = minute

        // ✅ 여기! dateComponents:repeats: 가 아니라
        // ✅ dateMatching:repeats: 가 맞음
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: true)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            throw NotiError.scheduleFailed(error.localizedDescription)
        }
    }

    func cancelDailyReminder(identifier: String = "neuronest.daily.reminder") {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
