import Foundation
import Combine

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var threads: [ChatThread] = []
    @Published var selectedThreadID: UUID?

    private let key = "ChatStore.threads.v1"

    init() {
        load()
        if threads.isEmpty {
            createThread()
        }
        if selectedThreadID == nil {
            selectedThreadID = threads.first?.id
        }
    }

    func createThread() {
        let t = ChatThread(title: "Hi", updatedAt: Date(), messages: [])
        threads.insert(t, at: 0)
        selectedThreadID = t.id
        save()
    }

    func select(_ id: UUID) {
        selectedThreadID = id
    }

    func deleteThread(_ id: UUID) {
        threads.removeAll { $0.id == id }
        if selectedThreadID == id {
            selectedThreadID = threads.first?.id
        }
        save()
    }

    func appendMessage(threadID: UUID, text: String, isUser: Bool) {
        guard let idx = threads.firstIndex(where: { $0.id == threadID }) else { return }
        threads[idx].messages.append(ChatMessage(text: text, isUser: isUser))
        threads[idx].updatedAt = Date()

        if threads[idx].title == "Hi", isUser {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                threads[idx].title = String(trimmed.prefix(24))
            }
        }

        let moved = threads.remove(at: idx)
        threads.insert(moved, at: 0)
        save()
    }

    func thread(_ id: UUID?) -> ChatThread? {
        guard let id else { return nil }
        return threads.first(where: { $0.id == id })
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(threads)
            UserDefaults.standard.set(data, forKey: key)
        } catch { }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            threads = try JSONDecoder().decode([ChatThread].self, from: data)
        } catch {
            threads = []
        }
    }
}
