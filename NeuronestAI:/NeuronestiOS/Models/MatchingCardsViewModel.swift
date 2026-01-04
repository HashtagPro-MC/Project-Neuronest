import Foundation
import SwiftUI
import Combine

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

@MainActor
final class MatchingCardsViewModel: ObservableObject {
    @Published var cards: [MemoryCard] = []
    @Published var moves: Int = 0
    @Published var elapsed: Int = 0
    @Published var isFinished: Bool = false

    // ✅ Analytics
    @Published var correctMatches: Int = 0
    @Published var wrongMatches: Int = 0

    // ✅ (옵션) 레벨 시스템이 있으면 여기서 관리
    @Published var currentLevel: Int = 1   // 없으면 1로 고정해도 OK

    // ✅ Reaction-time tracking (ms)
    private var stimulusTime: Date? = nil
    private(set) var reactionTimesMs: [Double] = []

    private var firstIndex: Int? = nil
    private var timer: Timer?

    init() { reset() }

    func reset() {
        stopTimer()
        elapsed = 0
        moves = 0
        isFinished = false
        firstIndex = nil
        correctMatches = 0
        wrongMatches = 0
        reactionTimesMs = []
        currentLevel = 1

        let emojis = ["🧠","⚡️","🍎","🧩","📚","🎧","🌙","☀️"]
        var deck = (emojis + emojis).map { MemoryCard(emoji: $0) }
        deck.shuffle()
        cards = deck

        startTimer()
        markStimulusShown()
    }

    private func markStimulusShown() {
        stimulusTime = Date()
    }

    private func recordReaction() {
        guard let t = stimulusTime else { return }
        let ms = Date().timeIntervalSince(t) * 1000.0
        if ms > 0 && ms < 30_000 {
            reactionTimesMs.append(ms)
        }
    }

    func tap(_ card: MemoryCard) {
        guard let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }
        if cards[idx].isFaceUp || cards[idx].isMatched { return }

        recordReaction()
        cards[idx].isFaceUp = true

        if let first = firstIndex {
            // second pick
            moves += 1

            if cards[first].emoji == cards[idx].emoji {
                correctMatches += 1
                cards[first].isMatched = true
                cards[idx].isMatched = true
                firstIndex = nil

                // (옵션) 레벨업 로직 넣고 싶으면 여기
                // 예: correctMatches가 4면 level 2...
                // currentLevel = 1 + correctMatches / 4

                checkFinish()
                markStimulusShown()
            } else {
                wrongMatches += 1
                let a = first
                firstIndex = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    self.cards[a].isFaceUp = false
                    self.cards[idx].isFaceUp = false
                    self.markStimulusShown()
                }
            }
        } else {
            // first pick
            firstIndex = idx
            markStimulusShown()
        }
    }

    private func checkFinish() {
        if cards.allSatisfy({ $0.isMatched }) {
            isFinished = true
            stopTimer()
        }
    }

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            // ✅ MainActor 안전 처리
            Task { @MainActor in
                self?.elapsed += 1
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// User manually ends the game. (Also used by the "End Game & Save" button.)
    func finishGame() {
        guard !isFinished else { return }
        isFinished = true
        stopTimer()
    }

    func buildSession() -> GameSession {
        // ✅ score 계산은 FocusDashViewModel 로직이 있다면 그걸로 넣는 게 베스트
        // 일단 기본 점수(간단): 정확도 + 속도 반영
        let total = max(1, correctMatches + wrongMatches)
        let acc = Double(correctMatches) / Double(total)   // 0..1
        let base = Int((acc * 100.0).rounded())

        return GameSession(
            id: UUID(),
            game: "matching",
            date: Date(),
            correct: correctMatches,
            wrong: wrongMatches,
            levelReached: currentLevel,
            durationSec: Double(elapsed),
            score: base,
            reactionTimesMs: reactionTimesMs
        )
    }
}

