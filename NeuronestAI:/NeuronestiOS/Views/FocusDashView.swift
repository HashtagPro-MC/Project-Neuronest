import SwiftUI
import Charts

struct FocusDashView: View {
    @EnvironmentObject var analytics: AnalyticsStore
    @StateObject private var vm = FocusDashViewModel()

    private struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double
        let p50rt: Double
    }

    var body: some View {
        let recentMatching = analytics.sessions.filter { $0.game == "matching" }.suffix(20)
        let points: [Point] = recentMatching.map { s in
            let total = max(1, s.correct + s.wrong)
            let acc = Double(s.correct) / Double(total) * 100.0
            // Try to read reactionTimesMs if available via Mirror; else compute 0
            let medianRT: Double = {
                let mirror = Mirror(reflecting: s)
                if let rts = mirror.children.first(where: { $0.label == "reactionTimesMs" })?.value as? [Double], !rts.isEmpty {
                    let sorted = rts.sorted()
                    return sorted[sorted.count/2]
                } else if let rtsInt = mirror.children.first(where: { $0.label == "reactionTimesMs" })?.value as? [Int], !rtsInt.isEmpty {
                    let sorted = rtsInt.sorted()
                    return Double(sorted[sorted.count/2])
                } else if let rts = mirror.children.first(where: { $0.label == "reactionTimes" })?.value as? [Double], !rts.isEmpty {
                    let sorted = rts.sorted()
                    return sorted[sorted.count/2]
                } else if let rtsInt = mirror.children.first(where: { $0.label == "reactionTimes" })?.value as? [Int], !rtsInt.isEmpty {
                    let sorted = rtsInt.sorted()
                    return Double(sorted[sorted.count/2])
                }
                return 0
            }()
            return Point(date: s.date, accuracy: acc, p50rt: medianRT)
        }

        let score = vm.score(from: analytics.sessions)
        let level = vm.level(for: score)

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("⚡️ Focus Dash")
                    .font(.system(size: 30, weight: .heavy))

                GroupBox("Current Focus") {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Score: \(score)/100")
                                .font(.title2.bold())
                            Text("Level: \(level.rawValue)")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(Color(.secondarySystemFill), lineWidth: 12)
                                .frame(width: 84, height: 84)
                            Circle()
                                .trim(from: 0, to: CGFloat(score) / 100.0)
                                .stroke(.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 84, height: 84)
                            Text("\(score)")
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if points.isEmpty {
                    GroupBox("No focus data yet") {
                        Text("먼저 Matching Cards를 몇 번 플레이하면 반응 속도(Reaction Time)와 정확도로 Focus Dash가 채워져.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    GroupBox("Reaction Time (median)") {
                        Chart(points) { p in
                            LineMark(
                                x: .value("Date", p.date),
                                y: .value("P50(ms)", p.p50rt)
                            )
                            PointMark(
                                x: .value("Date", p.date),
                                y: .value("P50(ms)", p.p50rt)
                            )
                        }
                        .frame(height: 180)
                    }

                    GroupBox("Accuracy") {
                        Chart(points) { p in
                            BarMark(
                                x: .value("Date", p.date),
                                y: .value("Accuracy", p.accuracy)
                            )
                        }
                        .chartYScale(domain: 0...100)
                        .frame(height: 160)
                    }

                    let last10 = Array(recentMatching.suffix(10))
                    let allRTs: [Double] = last10.flatMap { session in
                        let mirror = Mirror(reflecting: session)
                        if let rts = mirror.children.first(where: { $0.label == "reactionTimesMs" })?.value as? [Double] { return rts }
                        if let rtsInt = mirror.children.first(where: { $0.label == "reactionTimesMs" })?.value as? [Int] { return rtsInt.map(Double.init) }
                        if let rts = mirror.children.first(where: { $0.label == "reactionTimes" })?.value as? [Double] { return rts }
                        if let rtsInt = mirror.children.first(where: { $0.label == "reactionTimes" })?.value as? [Int] { return rtsInt.map(Double.init) }
                        return []
                    }
                    let sortedRTs = allRTs.sorted()
                    let avg = sortedRTs.isEmpty ? 0 : (sortedRTs.reduce(0, +) / Double(sortedRTs.count))
                    let p50 = sortedRTs.isEmpty ? 0 : sortedRTs[sortedRTs.count/2]
                    let p90 = sortedRTs.isEmpty ? 0 : sortedRTs[Int(Double(sortedRTs.count-1) * 0.9)]

                    GroupBox("Last 10 sessions (RT stats)") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avg: \(Int(avg))ms")
                            Text("P50: \(Int(p50))ms")
                            Text("P90: \(Int(p90))ms")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(.inline)
    }
}

