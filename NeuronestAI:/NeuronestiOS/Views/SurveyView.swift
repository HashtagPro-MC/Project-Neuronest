import SwiftUI

struct SurveyView: View {
    @EnvironmentObject var noti: NotificationManager
    @StateObject private var vm = SurveyViewModel()
    @State private var reminderStatus: String = ""

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Check-in Survey")
                        .font(.system(size: 26, weight: .heavy))

                    Text("간단한 체크인 설문으로 이번 주 컨디션을 기록해줘.")
                        .foregroundStyle(.secondary)

                    weeklyReminderSection

                    ForEach(vm.questions) { q in
                        GroupBox(q.title) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(q.options, id: \.self) { option in
                                    Button {
                                        vm.setAnswer(questionID: q.id, option: option)
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 15, weight: .semibold))
                                            Spacer()
                                            if vm.answers[q.id] == option {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Button {
                        Task { await vm.submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if vm.isLoading {
                                ProgressView().padding(.trailing, 6)
                            }
                            Text(vm.isLoading ? "Submitting..." : "Submit survey")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading || !vm.isComplete)

                    if let msg = vm.errorMessage {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    if !vm.cheerMessage.isEmpty {
                        Text("Cheer")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.top, 6)

                        Text(vm.cheerMessage)
                            .font(.system(size: 15))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                }
                .padding(16)
            }
        }
    }

    private var weeklyReminderSection: some View {
        GroupBox("Weekly Check-in Reminder") {
            VStack(alignment: .leading, spacing: 8) {
                Text("매주 설문 체크인을 잊지 않도록 알림을 받을 수 있어.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("Enable weekly reminder") {
                        Task { await enableWeeklyReminder() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Disable") {
                        noti.cancelWeeklyReminder()
                        reminderStatus = "Weekly reminder disabled."
                    }
                    .buttonStyle(.bordered)
                }

                if !reminderStatus.isEmpty {
                    Text(reminderStatus)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @MainActor
    private func enableWeeklyReminder() async {
        do {
            try await noti.requestPermission()
            try await noti.scheduleWeeklyReminder(
                weekday: 2, // Monday
                hour: 9,
                minute: 0,
                title: "Neuronest Weekly Check-in",
                body: "이번 주 설문 체크인을 완료해줘!"
            )
            reminderStatus = "Weekly reminder set for Monday 9:00 AM."
        } catch {
            reminderStatus = "알림 설정 실패: \(error.localizedDescription)"
        }
    }
}
