import SwiftUI
import Combine

@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var chatText: String = ""
    @Published var resultText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var cheerMessage: String = ""

    func analyze() async {
        errorMessage = nil
        resultText = ""
        cheerMessage = ""

        let trimmed = chatText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "분석할 채팅을 붙여넣어줘."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = try CohereClient()

            let system = """
            You are Neuronest AI research assistant.
            Analyze chats to extract structured insights. Do not include medical or legal advice.
            Keep outputs clear and concise.
            """

            let user = buildPrompt(chat: trimmed)

            resultText = try await client.chat(
                system: system,
                user: user,
                model: "command-r-plus",
                temperature: 0.2
            )
            await generateCheerMessage()
        } catch {
            errorMessage = error.localizedDescription
        }
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

    private func buildPrompt(chat: String) -> String {
        """
        Analyze the following chat log and produce a structured survey-style report.

        Output format:
        1) Summary (3 bullets)
        2) Detected Topics (up to 8, include short evidence quotes <= 12 words)
        3) User Goals & Intent (ranked)
        4) Pain Points / Frictions (ranked)
        5) Emotion & Tone (short)
        6) Suggested Next Actions (5 items)
        7) 5 Survey Questions to ask next (multiple-choice)

        Chat:
        ---
        \(chat)
        ---
        """
    }
}
