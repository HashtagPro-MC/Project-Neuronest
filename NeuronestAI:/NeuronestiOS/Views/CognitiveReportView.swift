import SwiftUI
import Charts

struct CognitiveReportView: View {
    @EnvironmentObject var analytics: AnalyticsStore
    @State private var sessions: [GameSession] = []

    @State private var aiText: String = ""
    @State private var isLoadingAI: Bool = false
    @State private var errorAI: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                HStack {
                    Text("📊 Cognitive Report")
                        .font(.system(size: 30, weight: .heavy))
                    Spacer()
                    Button("Refresh") { sessions = analytics.sessions }
                        .buttonStyle(.bordered)
                    Button("Clear", role: .destructive) {
                        analytics.clear()
                        sessions = analytics.sessions
                        aiText = ""
                        errorAI = nil
                    }
                    .buttonStyle(.bordered)
                }

                summaryBox

                if !sessions.isEmpty {
                    accuracyChart
                    timeChart
                    recentSessionsBox
                } else {
                    GroupBox("No data yet") {
                        Text("Matching Cards 게임을 한 번 끝내면 자동으로 기록이 저장돼. 그 다음 여기서 그래프/리포트가 보여!")
                            .foregroundStyle(.secondary)
                    }
                }

                aiSection
            }
            .padding(16)
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sessions = analytics.sessions
        }
        .onReceive(analytics.$sessions) { newValue in
            sessions = newValue
        }
    }

    private var summaryBox: some View {
        let last10 = Array(sessions.suffix(10))
        let totalCorrect = last10.reduce(0) { $0 + $1.correct }
        let totalWrong = last10.reduce(0) { $0 + $1.wrong }
        let total = totalCorrect + totalWrong
        let accPct = total == 0 ? 0 : Int((Double(totalCorrect) / Double(total) * 100).rounded())
        let accLevel = accuracyLevel(accPct)
        let avgSec = last10.isEmpty ? 0 : Int(Double(last10.reduce(0) { $0 + Int($1.durationSec.rounded()) }) / Double(last10.count))
        let rt = analytics.matchingRTStats(last: 10)
        return GroupBox("Summary (recent 10)") {
            VStack(alignment: .leading, spacing: 8) {
                Text("✅ \(totalCorrect)   ❌ \(totalWrong)   🎯 \(accLevel.rawValue)")
                    .font(.headline)
                Text("Avg time: \(avgSec)s · RT P50: \(Int(rt.p50))ms · Sessions: \(last10.count)")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                
            }
        }
    }

    private var accuracyChart: some View {
        let points = chartPoints()
        return GroupBox("Accuracy trend") {
            Chart(points) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Accuracy", p.accuracyPercent)
                )
                PointMark(
                    x: .value("Date", p.date),
                    y: .value("Accuracy", p.accuracyPercent)
                )
            }
            .chartYScale(domain: 0...100)
            .frame(height: 180)
        }
    }

    private var timeChart: some View {
        let points = chartPoints()
        return GroupBox("Time (seconds) trend") {
            Chart(points) { p in
                BarMark(
                    x: .value("Date", p.date),
                    y: .value("Seconds", p.seconds)
                )
            }
            .frame(height: 160)
        }
    }

    private var recentSessionsBox: some View {
        GroupBox("Recent sessions") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sessions.suffix(8)) { s in
                    let total = max(1, s.correct + s.wrong)
                    let accPct = Int((Double(s.correct) / Double(total) * 100).rounded())
                    let level = accuracyLevel(accPct)
                    Text("• \(s.game) — ✅\(s.correct) ❌\(s.wrong) · 🎯\(level.rawValue) · \(Int(s.durationSec.rounded()))s")
                        .font(.subheadline)
                }
            }
        }
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🤖 Neuronest AI Report")
                    .font(.title3.bold())
                Spacer()
                Button {
                    Task { await generateAIReport() }
                } label: {
                    HStack(spacing: 8) {
                        if isLoadingAI { ProgressView() }
                        Text(isLoadingAI ? "Analyzing..." : "Generate")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoadingAI || sessions.isEmpty)
            }

            if let errorAI {
                Text(errorAI).foregroundStyle(.red).font(.footnote)
            }

            if !aiText.isEmpty {
                Text(aiText)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
            } else {
                Text("버튼을 누르면 최근 기록을 기반으로 AI가 요약/강점/개선점/내일 목표를 만들어줘.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
    }

    private struct ReportPoint: Identifiable {
        let id = UUID()
        let date: Date
        let accuracyPercent: Double
        let seconds: Int
    }

    private func chartPoints() -> [ReportPoint] {
        sessions.suffix(20).map { s in
            let total = max(1, s.correct + s.wrong)
            let acc = Double(s.correct) / Double(total) * 100.0
            return ReportPoint(date: s.date, accuracyPercent: acc, seconds: Int(s.durationSec.rounded()))
        }
    }

    // Accuracy level (no % shown in UI)
    private func accuracyLevel(_ pct: Int) -> FocusLevel {
        switch pct {
        case 90...: return .good
        case 75..<90: return .moderate
        case 60..<75: return .mild
        case 45..<60: return .medium
        default: return .danger
        }
    }

    @MainActor
    private func generateAIReport() async {
        errorAI = nil
        isLoadingAI = true
        defer { isLoadingAI = false }

        do {
            let client = try MistralClient()
            let last = Array(sessions.suffix(12))

            let df = ISO8601DateFormatter()
            let lines = last.map { s in
                let total = max(1, s.correct + s.wrong)
                let accPct = Int((Double(s.correct) / Double(total) * 100).rounded())
                let level = accuracyLevel(accPct)
                let rtSorted = s.reactionTimesMs.sorted()
                let p50 = rtSorted.isEmpty ? 0 : Int(rtSorted[rtSorted.count/2].rounded())
                return "- \(s.game) | ✅\(s.correct) ❌\(s.wrong) 🎯\(level.rawValue) | \(Int(s.durationSec.rounded()))s | RT P50 \(p50)ms | \(df.string(from: s.date))"
            }.joined(separator: "\n")

            let prompt = """
            너는 Neuronest의 인지훈련 코치야.
            아래 '최근 기록'만 기반으로, 한국어로 친근하고 짧은 리포트를 만들어줘.
            의료 진단처럼 말하지 말고, 훈련/습관 코치 톤으로.

            출력 형식:
            1) 요약(2~3문장)
            2) 강점 1개
            3) 개선점 1개
            4) 내일 목표(숫자 포함) 1개
            5) 7일 계획(아주 짧게)

            최근 기록:
            \(lines)
            """

            aiText = try await client.generateReport(prompt: prompt)
        } catch {
            errorAI = error.localizedDescription
        }
    }
}
    