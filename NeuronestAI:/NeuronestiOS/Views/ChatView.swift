import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatStore: ChatStore
    let threadID: UUID
    
    @State private var input: String = ""
    @State private var isSending = false
    
    var body: some View {
        let thread = chatStore.thread(threadID)
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(thread?.messages ?? []) { m in
                                HStack {
                                    if m.isUser { Spacer() }
                                    Text(m.text)
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(m.isUser ? Color.blue.opacity(0.45) : Color.white.opacity(0.10))
                                        )
                                    if !m.isUser { Spacer() }
                                }
                                .id(m.id)
                            }
                        }
                        .padding(14)
                    }
                    .onChange(of: (thread?.messages.count ?? 0)) { _, _ in
                        if let last = thread?.messages.last?.id {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }
                
                Divider().opacity(0.2)
                
                HStack(spacing: 10) {
                    TextField("Type a message...", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSending)
                    
                    Button {
                        send()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(Color.blue.opacity(0.7)))
                    }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding(12)
                .background(Color.black)
            }
        }
        .navigationTitle(thread?.title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
    /*
     private func send() {
         let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
         guard !text.isEmpty else { return }
         input = ""
         isSending = true

         chatStore.appendMessage(threadID: threadID, text: text, isUser: true)

         Task {
             do {
                 let client = try MistralClient(model: "mistral-small-latest")
                 let reply = try await client.chat(
                     system: "You are Neuronest AI. Be supportive, short, and practical. Avoid medical diagnosis.",
                     user: text
                 )
                 await MainActor.run {
                     chatStore.appendMessage(threadID: threadID, text: reply, isUser: false)
                     isSending = false
                 }
             } catch {
                 await MainActor.run {
                     chatStore.appendMessage(threadID: threadID, text: "AI error: \(error.localizedDescription)", isUser: false)
                     isSending = false
                 }
             }
         }
     }
     */
    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        isSending = true

        chatStore.appendMessage(threadID: threadID, text: text, isUser: true)

        Task {
            do {
                let client = try MistralClient(model: "mistral-small-latest")
                let reply = try await client.chat(
                    system: "You are Neuronest AI. Be supportive, detailed, and practical. .",
                    user: text
                )
                await MainActor.run {
                    chatStore.appendMessage(threadID: threadID, text: reply, isUser: false)
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    chatStore.appendMessage(threadID: threadID, text: "AI error: \(error.localizedDescription)", isUser: false)
                    isSending = false
                }
            }
        }
    }
}
