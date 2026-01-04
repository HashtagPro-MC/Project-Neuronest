import Foundation

final class CohereChatService {
    private let apiKey: String
    private let apiURL = URL(string: "https://api.cohere.ai/v1/chat")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(_ message: String) async throws -> String {
        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Kotlin에서 만들던 JSON과 맞춰야 함 (프로젝트에 따라 key 이름이 다를 수 있음)
        let body: [String: Any] = [
            "message": message
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }

        if (200...299).contains(http.statusCode) {
            // Kotlin은 response JSON에서 "text"를 뽑았음
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return (json?["text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } else {
            let err = String(data: data, encoding: .utf8) ?? "Unknown error"
            return "⚠️ Cohere Error (\(http.statusCode)): \(err)"
        }
    }
}
