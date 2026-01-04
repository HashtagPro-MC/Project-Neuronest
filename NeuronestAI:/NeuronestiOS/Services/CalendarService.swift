import SwiftUI
import EventKit
import Combine

// ✅ UI에서 쓰는 모델(이미 CalendarEvent 만들어놨으면 이건 생략 가능)
struct CalendarIos: Identifiable, Hashable {
    let id: String                // EKEvent.eventIdentifier 사용
    var title: String
    var start: Date
    var end: Date
    var notes: String?
    var color: Color = .green

    var timeRangeText: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }
}

@MainActor
final class CalendarService: ObservableObject {

    enum CalError: Error, LocalizedError {
        case denied
        case noCalendar

        var errorDescription: String? {
            switch self {
            case .denied: return "Calendar permission denied."
            case .noCalendar: return "No writable calendar found."
            }
        }
    }

    private let store = EKEventStore()
    @Published var events: [EKEvent] = []

    func requestAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
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

    func fetchUpcoming(days: Int = 14) {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: days, to: start) ?? start
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let found = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        self.events = found
    }

    func createTrainingEvent(
        title: String,
        start: Date,
        durationMinutes: Int,
        notes: String? = nil
    ) throws {
        guard let cal = store.defaultCalendarForNewEvents else { throw CalError.noCalendar }

        let ev = EKEvent(eventStore: store)
        ev.calendar = cal
        ev.title = title
        ev.startDate = start
        ev.endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: start) ?? start
        ev.notes = notes

        try store.save(ev, span: .thisEvent, commit: true)
    }

    func deleteEvent(_ event: EKEvent) throws {
        try store.remove(event, span: .thisEvent, commit: true)
    }
}

// ✅ 여기부터 추가: UI에서 쓰기 편한 “wrapper API”
extension CalendarService {

    /// EKEvent -> CalendarEvent 변환
    func uiEvents(for day: Date) -> [CalendarEvent] {
        let cal = Calendar.current
        return events
            .filter { cal.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate < $1.startDate }
            .map { ek in
                CalendarEvent(
                    id: ek.eventIdentifier ?? UUID().uuidString,
                    title: ek.title ?? "(No title)",
                    start: ek.startDate,
                    end: ek.endDate,
                    color: .green,
                    notes: ek.notes,
                    
                )
            }
    }

    /// UI 이벤트 id로 EKEvent 찾기
    func ekEvent(by id: String) -> EKEvent? {
        store.event(withIdentifier: id)
    }

    /// UI에서 바로 Add
    func createEventUI(title: String, start: Date, end: Date, notes: String? = nil) throws {
        let minutes = max(1, Int(end.timeIntervalSince(start) / 60))
        try createTrainingEvent(title: title, start: start, durationMinutes: minutes, notes: notes)
        fetchUpcoming() // 저장 후 갱신
    }

    /// UI에서 바로 Delete
    func deleteEventUI(id: String) throws {
        guard let ev = ekEvent(by: id) else { return }
        try deleteEvent(ev)
        fetchUpcoming()
    }
}
