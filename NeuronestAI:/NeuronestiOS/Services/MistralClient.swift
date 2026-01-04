//
//  MistralClient.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 1/2/26.
//


import Foundation

struct MistralClient {
    enum MistralError: LocalizedError {
        case missingKey
        case badURL
        case badResponse(Int)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingKey: return "Mistral API key is missing."
            case .badURL: return "Bad Mistral URL."
            case .badResponse(let code): return "Mistral request failed (\(code))."
            case .emptyResponse: return "Mistral returned empty response."
            }
        }
    }

    /// Neuronest 리포트 전용 (코치 톤, 진단 금지, 짧고 구조화)
    /// - Parameters:
    ///   - sessionsText: CognitiveReportView에서 만든 "최근 기록" 텍스트(불렛 리스트 등)
    ///   - localeKR: 한국어 리포트 여부(기본 true)
    /// - Returns: 리포트 텍스트
    func generateReport(sessionsText: String, localeKR: Bool = true) async throws -> String {

        let system = localeKR ? """
        너는 'Neuronest' 인지훈련 코치다.
        - 의료 진단/질병 확정/치료 지시를 하지 마라.
        - 사용자에게 불안을 유발하지 말고, 훈련/습관 코치처럼 친근하고 명확하게 말해라.
        - 반드시 아래 '최근 기록'에 있는 정보만 근거로 작성해라.
        - 수치/횟수/시간이 있으면 1개 이상 포함해라.
        """ : """
        You are a cognitive training coach for 'Neuronest'.
        - Do NOT provide medical diagnosis or treatment instructions.
        - Be friendly and practical.
        - Use ONLY the provided recent logs as evidence.
        - Include at least one number (count/time/score).
        """

        let userPrompt = localeKR ? """
        아래 '최근 기록'만 기반으로, 한국어로 짧고 구조화된 리포트를 작성해줘.
        출력 형식(순서 고정):
        1) 요약(2~3문장)
        2) 강점 1개
        3) 개선점 1개
        4) 내일 목표(숫자 포함) 1개
        5) 7일 계획(아주 짧게)

        최근 기록:
        \(sessionsText)
        """ : """
        Using ONLY the 'Recent logs' below, write a short structured report.
        Output format (fixed order):
        1) Summary (2-3 sentences)
        2) One strength
        3) One improvement
        4) Tomorrow goal (include a number)
        5) 7-day plan (very short)

        Recent logs:
        \(sessionsText)
        """

        // 기존 chat() 호출 재사용
        return try await chat(system: system, user: userPrompt)
    }

    /// ✅ 그냥 "프롬프트만" 넣고 Neuronest 스타일로 만들고 싶을 때(옵션)
    func generateReport(prompt: String) async throws -> String {
        let system = """
        You are 'Neuronest' coaching assistant.
        No medical diagnosis. Friendly, practical, concise.
        """
        return try await chat(system: system, user: prompt)
    }

    private let apiKey: String
    private let model: String

    init(model: String = "mistral-small-latest") throws {
        // 1) Info.plist에서 읽기
        if let v = Bundle.main.object(forInfoDictionaryKey: "MISTRAL_API_KEY") as? String,
           !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.apiKey = v
        } else {
            throw MistralError.missingKey
        }
        self.model = model
    }

    struct ChatRequest: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int
    }

    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Msg: Codable { let role: String; let content: String }
            let message: Msg
        }
        let choices: [Choice]
    }

    func chat(system: String? = nil, user: String) async throws -> String {
        let url = URL(string: "https://api.mistral.ai/v1/chat/completions")
        guard let url else { throw MistralError.badURL }

        var messages: [ChatRequest.Message] = []
        if let system, !system.isEmpty {
            messages.append(.init(role: "system", content: system))
        }
        messages.append(.init(role: "user", content: user))

        let body = ChatRequest(
            model: model,
            messages: messages,
            temperature: 0.4,
            max_tokens: 600
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw MistralError.badResponse(-1) }
        guard (200...299).contains(http.statusCode) else { throw MistralError.badResponse(http.statusCode) }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MistralError.emptyResponse
        }
        return text


    }
}
