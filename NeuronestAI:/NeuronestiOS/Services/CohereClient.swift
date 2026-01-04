import Foundation

final class CohereClient {

    enum CohereError: Error, LocalizedError {
        case missingKey
        case badURL
        case http(Int, String)
        case decode(String)

        var errorDescription: String? {
            switch self {
            case .missingKey: return "COHERE_API_KEY가 설정되지 않았어. (Secrets.plist 확인)"
            case .badURL: return "Cohere URL이 이상해."
            case .http(let code, let body): return "Cohere HTTP \(code): \(body)"
            case .decode(let msg): return "Cohere 응답 파싱 실패: \(msg)"
            }
        }
    }

    private let apiKey: String

    init() throws {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict["COHERE_API_KEY"] as? String,
            !key.isEmpty
        else { throw CohereError.missingKey }

        self.apiKey = key
    }

    // v2/chat request
    struct Message: Codable {
        let role: String   // "system" | "user"
        let content: String
    }

    struct RequestBody: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double?
    }

    struct ResponseBody: Codable {
        struct MessageOut: Codable {
            struct Content: Codable {
                let type: String
                let text: String?
            }
            let content: [Content]
        }
        let message: MessageOut
    }

    func chat(system: String, user: String, model: String = "command-a-03-2025", temperature: Double = 0.3) async throws -> String {
        guard let url = URL(string: "https://api.cohere.com/v2/chat") else {
            throw CohereError.badURL
        }

        let body = RequestBody(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user)
            ],
            temperature: temperature
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw CohereError.http(-1, "No HTTP response")
        }

        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw CohereError.http(http.statusCode, body)
        }

        do {
            let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
            let text = decoded.message.content.compactMap { $0.text }.joined(separator: "\n")
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw CohereError.decode(error.localizedDescription)
        }
    }
}
