import Foundation

final class GeminiClient {
    enum GeminiError: Error, LocalizedError {
        case missingKey
        case badURL
        case http(Int, String)
        case decode(String)

        var errorDescription: String? {
            switch self {
            case .missingKey: return "GEMINI_API_KEY가 Secrets.plist에 설정되지 않았어."
            case .badURL: return "Gemini URL이 이상해."
            case .http(let code, let body): return "Gemini HTTP \(code): \(body)"
            case .decode(let msg): return "Gemini 응답 파싱 실패: \(msg)"
            }
        }
    }

    private let apiKey: String
    private let model: String

    init(model: String = "gemini-2.5-flash") throws {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict["GEMINI_API_KEY"] as? String,
            !key.isEmpty
        else {
            throw GeminiError.missingKey
        }
        self.apiKey = key
        self.model = model
    }

    func generateReport(prompt: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.badURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 450
            ]
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw GeminiError.http(-1, "No HTTP response")
        }
        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw GeminiError.http(http.statusCode, body)
        }

        do {
            // Minimal parse
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let candidates = obj?["candidates"] as? [[String: Any]]
            let content = candidates?.first?["content"] as? [String: Any]
            let parts = content?["parts"] as? [[String: Any]]
            let text = parts?.first?["text"] as? String
            return (text ?? "(empty)").trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw GeminiError.decode(error.localizedDescription)
        }
    }
}
