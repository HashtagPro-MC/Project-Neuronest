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
        .init(title: "이번 주 기분은 어땠나요?", options: ["😄 아주 좋아요", "🙂 괜찮아요", "😐 보통이에요", "🙁 조금 힘들었어요"]),
        .init(title: "수면은 충분했나요?", options: ["🛌 아주 잘 잤어요", "🙂 괜찮았어요", "😐 보통이에요", "😴 부족했어요"]),
        .init(title: "집중이 잘 됐나요?", options: ["🔥 매우 잘 됐어요", "🙂 괜찮았어요", "😐 보통이에요", "🌧️ 어려웠어요"]),
        .init(title: "기억력 게임/훈련을 얼마나 했나요?", options: ["✅ 4회 이상", "✅ 2~3회", "✅ 1회", "❌ 못했어요"]),
        .init(title: "이번 주에 가장 하고 싶은 변화는?", options: ["🚶 산책/활동 늘리기", "🍎 식단 챙기기", "🧠 훈련 꾸준히", "😴 휴식 늘리기"])
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
