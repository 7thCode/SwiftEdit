import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var content: String

    enum Role {
        case user, assistant
    }
}

struct LLMPanelView: View {
    let documentText: String
    @Environment(LLMService.self) private var llmService
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showModelPicker = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messageList
            Divider()
            inputArea
        }
        .background(.background)
        .sheet(isPresented: $showModelPicker) {
            ModelPickerView()
                .environment(llmService)
                .frame(width: 360, height: 160)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "brain")
            Text("AI アシスタント")
                .font(.headline)
            Spacer()
            Button {
                showModelPicker = true
            } label: {
                Image(systemName: "cpu")
            }
            .help("モデルを選択")
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if messages.isEmpty {
                        emptyStateView
                    }
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(12)
            }
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: messages.last?.content) {
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("ドキュメントについて質問できます")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("メッセージを入力...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        send()
                    }
                }

            if llmService.isGenerating {
                Button {
                    llmService.cancel()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !llmService.isGenerating &&
        llmService.modelState != .notLoaded &&
        llmService.modelState != .loading
    }

    private func send() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        inputText = ""

        messages.append(ChatMessage(role: .user, content: prompt))

        let assistantIndex = messages.count
        messages.append(ChatMessage(role: .assistant, content: ""))

        llmService.generate(
            documentText: documentText,
            userPrompt: prompt,
            onToken: { [assistantIndex] token in
                Task { @MainActor in
                    messages[assistantIndex].content += token
                }
            },
            onComplete: {}
        )
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            Text(message.content.isEmpty ? "…" : message.content)
                .font(.system(size: 13))
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(message.role == .user
                              ? Color.accentColor.opacity(0.15)
                              : Color(nsColor: .controlBackgroundColor))
                )
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Image(systemName: "person.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }
}
