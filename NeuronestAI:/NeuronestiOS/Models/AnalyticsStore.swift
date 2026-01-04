import Foundation
import Combine

// MARK: - Session Model

struct GameSession: Identifiable, Codable {
    let id: UUID
    let game: String               // e.g., "NumberMemory", "matching"
    let date: Date
    let correct: Int
    let wrong: Int
    let levelReached: Int          // 최고 도달 레벨 (없으면 0 넣기)
    let durationSec: Double        // 플레이 시간(초)
    let score: Int                 // 계산된 점수
    var reactionTimesMs: [Double] = []
}

// MARK: - Analytics Store

@MainActor
final class AnalyticsStore: ObservableObject {
    @Published private(set) var sessions: [GameSession] = []

    private let key = "NN_analytics_sessions_v2"

    init() { load() }

    // 전체 삭제
    func clear() {
        sessions.removeAll()
        UserDefaults.standard.removeObject(forKey: key)
    }

    // ✅ 공용: 세션 추가 (Matching/NumberMemory 모두 이걸로 저장 가능)
    func addSession(_ session: GameSession) {
        sessions.append(session)
        persist()
    }

    // ✅ 네가 이미 쓰던 호출 호환용
    func record(session: GameSession) {
        addSession(session)
    }

    // ✅ Number Memory 결과 저장 (기존 함수 유지)
    func addNumberMemorySession(correct: Int, wrong: Int, levelReached: Int, durationSec: Double) {
        // 점수 규칙:
        // - 정답 1개당 +10
        // - 오답 1개당 -5 (최소 0)
        // - 도달 레벨 보너스 + (levelReached * 3)
        let raw = (correct * 10) - (wrong * 5) + (levelReached * 3)
        let score = max(0, raw)

        let s = GameSession(
            id: UUID(),
            game: "NumberMemory",
            date: Date(),
            correct: correct,
            wrong: wrong,
            levelReached: levelReached,
            durationSec: durationSec,
            score: score,
            reactionTimesMs: []
        )
        addSession(s)
    }

    // ✅ 총점(전체)
    var totalScoreAll: Int {
        sessions.reduce(0) { $0 + $1.score }
    }

    // ✅ 최근 N개 총점
    func totalScore(last n: Int) -> Int {
        Array(sessions.suffix(n)).reduce(0) { $0 + $1.score }
    }

    // ✅ 최근 14일 일별 점수 합 (그래프용)
    func dailyScorePoints(days: Int = 14) -> [DailyPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -(days - 1), to: today) ?? today

        var bucket: [Date: Int] = [:]
        for i in 0..<days {
            let d = cal.date(byAdding: .day, value: i, to: start) ?? start
            bucket[d] = 0
        }

        for s in sessions {
            let d = cal.startOfDay(for: s.date)
            if bucket[d] != nil {
                bucket[d, default: 0] += s.score
            }
        }

        return bucket
            .map { DailyPoint(date: $0.key, score: $0.value) }
            .sorted { $0.date < $1.date }
    }

    struct DailyPoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Int
    }

    // ✅ Matching Cards 같은 RT 통계용 (없어서 에러났던 부분 해결)
    struct RTStats {
        let p50: Double
        let p90: Double
        let count: Int
    }

    func matchingRTStats(last n: Int = 10) -> RTStats {
        let recent = sessions
            .filter { $0.game.lowercased() == "matching" }
            .suffix(n)

        let all = recent.flatMap { $0.reactionTimesMs }.sorted()
        guard !all.isEmpty else { return RTStats(p50: 0, p90: 0, count: 0) }

        func percentile(_ p: Double) -> Double {
            let idx = Int((Double(all.count - 1) * p).rounded())
            return all[min(max(idx, 0), all.count - 1)]
        }

        return RTStats(
            p50: percentile(0.50),
            p90: percentile(0.90),
            count: all.count
        )
    }

    // MARK: - Persistence
    private func persist() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // ignore (do not crash)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let arr = try? JSONDecoder().decode([GameSession].self, from: data) else {
            sessions = []
            return
        }
        sessions = arr
    }
}
