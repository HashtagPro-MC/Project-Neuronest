/* import Foundation
//import EventKit
import SwiftUI

@MainActor
final class CalendarService: ObservableObject {

    enum CalError: Error, LocalizedError {
        case denied
        case noDefaultCalendar

        var errorDescription: String? {
            switch self {
            case .denied:
                return "Calendar permission denied. Settings에서 Calendar 권한을 켜줘."
            case .noDefaultCalendar:
                return "기본 캘린더를 찾을 수 없어."
            }
        }
    }

    private let store = EKEventStore()

    @Published var events: [EKEvent] = []

    func requestAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)s
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = try await store.requestFullAccessToEvents()
            if !granted { throw CalError.denied }
        default:
            throw CalError.denied
        }
    }

    func fetch(rangeDays: Int = 60, around date: Date = .now) {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -rangeDays, to: date) ?? date
        let end   = cal.date(byAdding: .day, value:  rangeDays, to: date) ?? date

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let found = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        self.events = found
    }

    func addEvent(title: String, start: Date, end: Date, notes: String? = nil) throws {
        guard let cal = store.defaultCalendarForNewEvents else {
            throw CalError.noDefaultCalendar
        }
        let ev = EKEvent(eventStore: store)
        ev.calendar = cal
        ev.title = title
        ev.startDate = start
        ev.endDate = end
        ev.notes = notes
        try store.save(ev, span: .thisEvent, commit: true)
    }

    func deleteEvent(_ event: EKEvent) throws {
        try store.remove(event, span: .thisEvent, commit: true)
    }
}
 /**/*/
