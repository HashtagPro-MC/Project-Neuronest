import SwiftUI
import Combine

@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var cheerMessage: String = ""

    struct SurveyQuestion: Identifiable {
        let id = UUID()
        let title: String
        let options: [String]
    }

    let questions: [SurveyQuestion] = [
        .init(title: "How was your mood this week?", options: ["😄 Very good", "🙂 Pretty good", "😐 Okay", "🙁 A bit tough"]),
        .init(title: "Did you get enough sleep?", options: ["🛌 Slept very well", "🙂 Pretty well", "😐 Okay", "😴 Not enough"]),
        .init(title: "Were you able to focus?", options: ["🔥 Very well", "🙂 Pretty well", "😐 Okay", "🌧️ It was hard"]),
        .init(title: "How often did you do memory training/games?", options: ["✅ 4+ times", "✅ 2–3 times", "✅ 1 time", "❌ Not at all"]),
        .init(title: "What change would you like most this week?", options: ["🚶 More walking/activity", "🍎 Better meals", "🧠 Keep training", "😴 More rest"])
    ]

    @Published var answers: [UUID: String] = [:]

    func setAnswer(questionID: UUID, option: String) {
        answers[questionID] = option
    }

    var isComplete: Bool {
        answers.keys.count == questions.count
    }

    func submit() async {
        errorMessage = nil
        cheerMessage = ""

        guard isComplete else {
            errorMessage = "모든 질문에 답해줘."
            return
        }

        isLoading = true
        defer { isLoading = false }

        await generateCheerMessage()
    }

    @MainActor
    private func generateCheerMessage() async {
        do {
            let client = try MistralClient(model: "mistral-small-latest")
            let prompt = """
            Write one short, cheerful sentence to encourage the user after completing their weekly check-in survey.
            Keep it positive, supportive, and friendly. No medical advice.
            """
            cheerMessage = try await client.chat(system: nil, user: prompt)
        } catch {
            cheerMessage = "정말 잘했어! 이번 주도 힘내자 💪"
        }
    }
}
