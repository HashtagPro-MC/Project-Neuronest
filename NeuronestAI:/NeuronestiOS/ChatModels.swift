import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let isUser: Bool
    let createdAt: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.createdAt = createdAt
    }
}

struct ChatThread: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var updatedAt: Date
    var messages: [ChatMessage]

    init(id: UUID = UUID(), title: String = "Hi", updatedAt: Date = Date(), messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.messages = messages
    }
}
