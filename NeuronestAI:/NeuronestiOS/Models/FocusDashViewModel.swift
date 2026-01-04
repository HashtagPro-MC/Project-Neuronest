import Foundation
import Combine

enum FocusLevel: String {
    case good = "Good"
    case moderate = "Moderate"
    case mild = "Mild"
    case medium = "Medium"
    case danger = "Danger"
}

@MainActor
final class FocusDashViewModel: ObservableObject {
    /// Simple heuristic score (0...100) based on reaction time and accuracy.
    func score(from sessions: [GameSession]) -> Int {
        let recent = sessions.filter { $0.game == "matching" }.prefix(10)
        guard !recent.isEmpty else { return 0 }

        // Accuracy (0...1)
        let totals = recent.reduce(into: (c: 0, w: 0)) { r, s in
            r.c += s.correct
            r.w += s.wrong
        }
        let denom = max(1, totals.c + totals.w)
        let acc = Double(totals.c) / Double(denom)

        // Reaction time median (ms)
        let allRT = recent.flatMap { $0.reactionTimesMs }.sorted()
        let p50 = allRT.isEmpty ? 1500.0 : allRT[allRT.count / 2]

        // Map: 500ms -> 1.0, 2500ms -> 0.0 (clamped)
        let rtNorm = max(0.0, min(1.0, (2500.0 - p50) / 2000.0))

        // Weighted score
        let score = (acc * 0.55 + rtNorm * 0.45) * 100.0
        return Int(score.rounded())
    }

    func level(for score: Int) -> FocusLevel {
        switch score {
        case 85...: return .good
        case 70..<85: return .moderate
        case 55..<70: return .mild
        case 40..<55: return .medium
        default: return .danger
        }
    }
}
