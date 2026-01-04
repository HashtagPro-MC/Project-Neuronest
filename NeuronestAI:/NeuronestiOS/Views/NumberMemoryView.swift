//
//  NumberMemoryView.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 1/2/26.
//

import SwiftUI

struct NumberMemoryView: View {
    @EnvironmentObject var analytics: AnalyticsStore

    @State private var level: Int = 1
    @State private var phase: Phase = .showing
    @State private var currentNumber: String = ""
    @State private var input: String = ""
    @State private var revealTask: Task<Void, Never>? = nil
    @State private var correct: Int = 0
    @State private var wrong: Int = 0

    @State private var rounds: Int = 0
    @State private var totalSpan: Int = 0
    @State private var maxSpan: Int = 1

    @State private var showMs: UInt64 = 1_200_000_000 // 1.2s in ns
    @State private var startedAt: Date = Date()

    enum Phase: Equatable {
        case showing
        case input
        case feedback(isCorrect: Bool, correct: String)
        case ended
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                header

                card

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .navigationTitle("Number Memory")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startedAt = Date()
            resetRound()
        }
        .onChange(of: level) { _ in
            if phase != .ended { resetRound() }
        }
        .onChange(of: phase) { newPhase in
            guard phase != .ended else { return }
        }
    }

    private var header: some View {
        HStack {
            Chip(text: "Level \(level)")
            Chip(text: "✅ \(correct)  ❌ \(wrong)")
            Chip(text: "Max \(maxSpan)")
            Spacer()
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            Text(titleText)
                .font(.system(size: 20, weight: .bold))

            if phase == .showing {
                Text(currentNumber)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text("Showing for \(Int(Double(showMs)/1_000_000.0)) ms")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if phase == .input {
                TextField("Answer", text: $input)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.06)))
                    .onChange(of: input) { newValue in
                        // 숫자만 + 길이 제한
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue { input = filtered }
                        if input.count > 18 { input = String(input.prefix(18)) }
                    }

                Button {
                    submit()
                } label: {
                    Text("Submit")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text("Miss 3 times → auto save")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if case let .feedback(isCorrect, correctAnswer) = phase {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(isCorrect ? .green : .red)
                Text(isCorrect ? "Correct" : "Wrong")
                    .font(.system(size: 18, weight: .bold))
                if !isCorrect {
                    Text("Answer: \(correctAnswer)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if phase == .ended {
                let avg = rounds == 0 ? 0 : Double(totalSpan) / Double(rounds)
                Text("✅ \(correct)   ❌ \(wrong)")
                    .font(.system(size: 18, weight: .bold))
                Text("Max span: \(maxSpan)")
                Text(String(format: "Avg span: %.2f", avg))
                    .foregroundStyle(.secondary)

                Button {
                    restart()
                } label: {
                    Text("Play Again")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.primary.opacity(0.06)))
    }

    // MARK: - Game Logic

    private func resetRound() {
        // 이전 예약 취소
        revealTask?.cancel()
        revealTask = nil

        phase = .showing
        currentNumber = generateNumber(digits: level)
        input = ""

        // 레벨 올라갈수록 조금 더 보여주기
        let ms = min(2600, 900 + level * 120)
        showMs = UInt64(ms) * 1_000_000

        // ✅ 여기서 바로 자동 전환 예약
        revealTask = Task {
            try? await Task.sleep(nanoseconds: showMs)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if phase == .showing {
                    phase = .input
                }
            }
        }
    }

    private func submit() {
        let ok = (input == currentNumber)
        phase = .feedback(isCorrect: ok, correct: currentNumber)

        rounds += 1
        totalSpan += level
        if ok { maxSpan = max(maxSpan, level) }

        if ok {
            correct += 1
            level += 1
        } else {
            wrong += 1
            level = max(1, level - 1)
        }

        if wrong >= 3 {
            scheduleAdvanceToEnd()
            return
        }
        scheduleAdvanceToNextRound()
    }

    private func scheduleAdvanceToNextRound() {
        // Show feedback briefly then move to next round
        revealTask?.cancel()
        revealTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
            guard !Task.isCancelled else { return }
            await MainActor.run {
                resetRound()
            }
        }
    }

    private func scheduleAdvanceToEnd() {
        // Show feedback briefly then end
        revealTask?.cancel()
        revealTask = Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                endAndSave()
            }
        }
    }

    private func endAndSave() {
        phase = .ended
        let duration = Date().timeIntervalSince(startedAt)
        let avg = rounds == 0 ? 0 : Double(totalSpan) / Double(rounds)

        // Build a session record with required fields
        let session = GameSession(
            id: UUID(),
            game: "NumberMemory",
            date: Date(),
            correct: correct,
            wrong: wrong,
            levelReached: maxSpan,
            durationSec: duration,
            score: maxSpan,
            reactionTimesMs: []
        )
        // Send to analytics store. If your API differs, adjust the call accordingly.
        analytics.record(session: session)
    }

    private func restart() {
        level = 1
        phase = .showing
        correct = 0
        wrong = 0
        rounds = 0
        totalSpan = 0
        maxSpan = 1
        startedAt = Date()
        resetRound()
    }

    // MARK: - Helpers

    private var titleText: String {
        switch phase {
        case .showing: return "Memorize"
        case .input: return "Type it"
        case .feedback(let ok, _): return ok ? "Nice!" : "Try again"
        case .ended: return "Finished"
        }
    }

    private func generateNumber(digits: Int) -> String {
        // 앞자리가 0이면 쉬워져서 1~9로 시작
        let first = Int.random(in: 1...9)
        if digits == 1 { return "\(first)" }
        var s = "\(first)"
        for _ in 1..<digits { s.append("\(Int.random(in: 0...9))") }
        return s
    }
}

// 작은 칩 UI
private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.primary.opacity(0.08)))
        
    }
}

