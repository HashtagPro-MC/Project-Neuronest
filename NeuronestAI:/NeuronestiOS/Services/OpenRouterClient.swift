//
//  OpenRouterClient.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 1/1/26.
//


import Foundation

final class OpenRouterClient {
    enum ORouterError: Error, LocalizedError {
        case missingKey
        case badURL
        case http(Int, String)
        case decode(String)

        var errorDescription: String? {
            switch self {
            case .missingKey: return "OPENROUTER_API_KEY가 설정되지 않았어. (Secrets.plist)"
            case .badURL: return "OpenRouter URL이 이상해."
            case .http(let code, let body): return "OpenRouter HTTP \(code): \(body)"
            case .decode(let msg): return "OpenRouter 응답 파싱 실패: \(msg)"
            }
        }
    }

    private let apiKey: String
    private let appName: String?
    private let appURL: String?

    init() throws {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict["OPENROUTER_API_KEY"] as? String,
            !key.isEmpty
        else { throw ORouterError.missingKey }

        self.apiKey = key
        self.appName = dict["OPENROUTER_APP_NAME"] as? String
        self.appURL = dict["OPENROUTER_APP_URL"] as? String
    }

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Req: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double?
        let max_tokens: Int?
    }

    struct Res: Codable {
        struct Choice: Codable {
            struct Msg: Codable {
                let role: String?
                let content: String?
            }
            let message: Msg
        }
        let choices: [Choice]
    }

    /// model 예: "openai/gpt-4o-mini", "google/gemini-2.0-flash-001", "meta-llama/llama-3.1-70b-instruct"
    func chat(
        model: String,
        system: String,
        user: String,
        temperature: Double = 0.3,
        maxTokens: Int = 350
    ) async throws -> String {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw ORouterError.badURL
        }

        let body = Req(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user)
            ],
            temperature: temperature,
            max_tokens: maxTokens
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // OpenRouter 권장 헤더(선택이지만 넣는 게 좋음)
        if let appName, !appName.isEmpty {
            req.addValue(appName, forHTTPHeaderField: "X-Title")
        }
        if let appURL, !appURL.isEmpty {
            req.addValue(appURL, forHTTPHeaderField: "HTTP-Referer")
        }

        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw ORouterError.http(-1, "No HTTP response")
        }

        if !(200...299).contains(http.statusCode) {
            let txt = String(data: data, encoding: .utf8) ?? "(no body)"
            throw ORouterError.http(http.statusCode, txt)
        }

        do {
            let decoded = try JSONDecoder().decode(Res.self, from: data)
            let text = decoded.choices.first?.message.content ?? ""
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw ORouterError.decode(error.localizedDescription)
        }
    }
}
extension OpenRouterClient {
    /// CognitiveReportView에서 쓰는 단일 진입점
    func generateReport(prompt: String) async throws -> String {
        try await chat(
            model: "nex-agi/deepseek-v3.1-nex-n1:free", // 여기 원하는 OpenRouter 모델로 바꿔도 됨
            system: """
            You are Neuronest AI, a cognitive training coach.
            Do not provide medical diagnosis.
            Keep it friendly and short.
            Also if the user says tell me a joke, do not repeat the same joke okay?
            """,
            user: prompt,
            temperature: 0.4,
            maxTokens: 450
        )
    }
}

