import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var chatStore: ChatStore
    @State private var confirmDelete: ChatThread?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List {
                Button("+ New Chat") {
                    chatStore.createThread()
                }
                .foregroundStyle(.white)
                .listRowBackground(Color.white.opacity(0.06))

                ForEach(chatStore.threads) { t in
                    NavigationLink {
                        ChatView(threadID: t.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(t.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(t.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                    .swipeActions {
                        Button(role: .destructive) {
                            confirmDelete = t
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Chats")
        .alert("Delete chat?", isPresented: Binding(
            get: { confirmDelete != nil },
            set: { if !$0 { confirmDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { confirmDelete = nil }
            Button("Delete", role: .destructive) {
                if let t = confirmDelete {
                    chatStore.deleteThread(t.id)
                }
                confirmDelete = nil
            }
        } message: {
            Text("This will permanently delete this chat thread.")
        }
    }
}
