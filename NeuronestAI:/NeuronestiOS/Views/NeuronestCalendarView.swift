import SwiftUI
import EventKit

// MARK: - UI Model (EKEvent -> UI)
struct CalendarEvent: Identifiable, Hashable {
    let id: String              // EKEvent.eventIdentifier
    var title: String
    var start: Date
    var end: Date
    var color: Color
    var notes: String?

    var timeRangeText: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }
}

enum CalendarMode: String, CaseIterable, Identifiable {
    case month = "Month"
    case week  = "Week"
    case day   = "Day"
    case events = "Events"
    var id: String { rawValue }
}

struct NeuronestCalendarView: View {
    @EnvironmentObject var calendarService: CalendarService

    @State private var mode: CalendarMode = .month
    @State private var selectedDate: Date = .now

    @State private var showDetails = false
    @State private var selectedEvent: CalendarEvent? = nil

    @State private var showAdd = false
    @State private var alertMsg: String? = nil

    @State private var uiEvents: [CalendarEvent] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                HeaderBar(selectedDate: $selectedDate, onRefresh: {
                    calendarService.fetchUpcoming(days: 30)
                    rebuildUIEvents()
                })

                ModeChips(mode: $mode)

                MiniWeekStrip(selectedDate: $selectedDate)

                Divider().opacity(0.25)

                Group {
                    switch mode {
                    case .month:
                        MonthEventList(
                            selectedDate: selectedDate,
                            events: eventsForSelectedDay
                        ) { ev in
                            selectedEvent = ev
                            showDetails = true
                        }

                    case .week, .day:
                        DayTimelineView(
                            selectedDate: selectedDate,
                            events: eventsForSelectedDay
                        ) { ev in
                            selectedEvent = ev
                            showDetails = true
                        }

                    case .events:
                        AllEventsList(events: uiEvents) { ev in
                            selectedEvent = ev
                            showDetails = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            FloatingAddButton {
                showAdd = true
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)

        // ✅ permission + load
        .task {
            do {
                try await calendarService.requestAccess()
                calendarService.fetchUpcoming(days: 30)
                rebuildUIEvents()
            } catch {
                alertMsg = error.localizedDescription
            }
        }

        // ✅ EKEvent list 변경되면 UI 재생성
        .onReceive(calendarService.$events) { _ in
            rebuildUIEvents()
        }

        // ✅ Add Sheet
        .sheet(isPresented: $showAdd) {
            AddTrainingEventSheet { title, start, minutes, notes in
                do {
                    try calendarService.createTrainingEvent(
                        title: title,
                        start: start,
                        durationMinutes: minutes,
                        notes: notes
                    )
                    calendarService.fetchUpcoming(days: 30)
                    rebuildUIEvents()
                    showAdd = false
                } catch {
                    alertMsg = error.localizedDescription
                }
            }
        }

        // ✅ Details Sheet
        .sheet(isPresented: $showDetails) {
            if let ev = selectedEvent {
                EventDetailsSheet(
                    event: ev,
                    onDelete: {
                        do {
                            if let ek = calendarService.events.first(where: { $0.eventIdentifier == ev.id }) {
                                try calendarService.deleteEvent(ek)
                                calendarService.fetchUpcoming(days: 30)
                                rebuildUIEvents()
                                showDetails = false
                            } else {
                                alertMsg = "Could not find the original event to delete."
                            }
                        } catch {
                            alertMsg = error.localizedDescription
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }

        // ✅ error alert
        .alert("Error", isPresented: Binding(
            get: { alertMsg != nil },
            set: { if !$0 { alertMsg = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMsg ?? "")
        }
    }

    private var eventsForSelectedDay: [CalendarEvent] {
        let cal = Calendar.current
        return uiEvents
            .filter { cal.isDate($0.start, inSameDayAs: selectedDate) }
            .sorted { $0.start < $1.start }
    }

    private func rebuildUIEvents() {
        // EKEvent -> CalendarEvent 변환
        uiEvents = calendarService.events.map { ek in
            CalendarEvent(
                id: ek.eventIdentifier ?? UUID().uuidString,
                title: ek.title ?? "(No title)",
                start: ek.startDate,
                end: ek.endDate,
                color: .green,
                notes: ek.notes
            )
        }
        .sorted { $0.start < $1.start }
    }
}

// MARK: - Header
struct HeaderBar: View {
    @Binding var selectedDate: Date
    var onRefresh: () -> Void

    var body: some View {
        HStack {
            Button {} label: {
                HStack(spacing: 6) {
                    Text(monthTitle(selectedDate))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 10) {
                CircleIcon(systemName: "arrow.clockwise") { onRefresh() }
            }
        }
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy MMMM"
        return f.string(from: date)
    }
}

struct CircleIcon: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Chips
struct ModeChips: View {
    @Binding var mode: CalendarMode

    var body: some View {
        HStack(spacing: 12) {
            ForEach(CalendarMode.allCases) { m in
                Button {
                    mode = m
                } label: {
                    VStack(spacing: 6) {
                        Circle()
                            .stroke(m == mode ? Color.green : Color.white.opacity(0.15), lineWidth: 2)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: icon(for: m))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                            )

                        Text(m.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
    }

    private func icon(for m: CalendarMode) -> String {
        switch m {
        case .month: return "calendar"
        case .week: return "calendar.day.timeline.left"
        case .day: return "calendar.badge.clock"
        case .events: return "list.bullet"
        }
    }
}

// MARK: - MiniWeekStrip
struct MiniWeekStrip: View {
    @Binding var selectedDate: Date
    private let cal = Calendar.current

    var body: some View {
        let week = weekDates(around: selectedDate)

        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(week, id: \.self) { d in
                    let isSelected = cal.isDate(d, inSameDayAs: selectedDate)
                    let isToday = cal.isDateInToday(d)

                    Button {
                        selectedDate = d
                    } label: {
                        VStack(spacing: 6) {
                            Text(weekdayShort(d))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))

                            Text(dayNumber(d))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(isSelected ? .black : .white)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(isSelected ? Color.green : Color.clear))
                                .overlay(
                                    Circle().stroke(isToday && !isSelected ? Color.green.opacity(0.9) : .clear, lineWidth: 2)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 46, height: 4)
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
    }

    private func weekDates(around date: Date) -> [Date] {
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func weekdayShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}

// MARK: - Lists / Rows (네 기존 UI 그대로)
struct MonthEventList: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let onTapEvent: (CalendarEvent) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(sectionTitle(date: selectedDate))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 6)

                if events.isEmpty {
                    EmptyStateCard(text: "No events for this day.")
                } else {
                    ForEach(events) { ev in
                        EventRowCard(event: ev)
                            .onTapGesture { onTapEvent(ev) }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func sectionTitle(date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: date)
    }
}

struct DayTimelineView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let onTapEvent: (CalendarEvent) -> Void

    private let hours = Array(8...20)

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(hours, id: \.self) { h in
                    HStack(alignment: .top, spacing: 12) {
                        Text(hourText(h))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 48, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)

                            ForEach(eventsAtHour(h)) { ev in
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(ev.color)
                                        .frame(width: 8)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ev.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text(ev.timeRangeText)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                                .onTapGesture { onTapEvent(ev) }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    private func hourText(_ hour: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = 0
        let d = Calendar.current.date(from: comps) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: d)
    }

    private func eventsAtHour(_ hour: Int) -> [CalendarEvent] {
        let cal = Calendar.current
        return events.filter { cal.component(.hour, from: $0.start) == hour }
    }
}

struct AllEventsList: View {
    let events: [CalendarEvent]
    let onTapEvent: (CalendarEvent) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("All Events")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 6)

                if events.isEmpty {
                    EmptyStateCard(text: "No events yet.")
                } else {
                    ForEach(events.sorted(by: { $0.start > $1.start })) { ev in
                        EventRowCard(event: ev)
                            .onTapGesture { onTapEvent(ev) }
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}

struct EventRowCard: View {
    let event: CalendarEvent
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(event.color)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(event.timeRangeText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
    }
}

struct EmptyStateCard: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
    }
}

struct FloatingAddButton: View {
    let action: () -> Void
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.green))
                        .shadow(radius: 10)
                }
                .padding(.trailing, 18)
                .padding(.bottom, 22)
            }
        }
    }
}

// ✅ Delete 가능한 Details Sheet
struct EventDetailsSheet: View {
    let event: CalendarEvent
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary.opacity(0.35))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            Text("Event Details")
                .font(.system(size: 20, weight: .bold))

            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(event.color.opacity(0.20))
                    .overlay(
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.title)
                                .font(.system(size: 22, weight: .heavy))
                            Text(event.timeRangeText)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(16),
                        alignment: .leading
                    )
                    .frame(height: 110)

                if let notes = event.notes, !notes.isEmpty {
                    Text("Notes")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.system(size: 15, weight: .semibold))
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }
}
