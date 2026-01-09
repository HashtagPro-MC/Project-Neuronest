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
                    Text("Survey / Chat Analyzer")
                        .font(.system(size: 26, weight: .heavy))

                    Text("여기에 분석할 채팅을 붙여넣고, Cohere로 분석해.")
                        .foregroundStyle(.secondary)

                    weeklyReminderSection

                    TextEditor(text: $vm.chatText)
                        .frame(minHeight: 220)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )

                    Button {
                        Task { await vm.analyze() }
                    } label: {
                        HStack {
                            Spacer()
                            if vm.isLoading {
                                ProgressView().padding(.trailing, 6)
                            }
                            Text(vm.isLoading ? "Analyzing..." : "Analyze with Cohere")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading)

                    if let msg = vm.errorMessage {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    if !vm.resultText.isEmpty {
                        Text("Result")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.top, 6)

                        Text(vm.resultText)
                            .font(.system(size: 15))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
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
