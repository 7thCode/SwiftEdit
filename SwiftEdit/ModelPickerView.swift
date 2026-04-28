import SwiftUI
import AppKit

struct ModelPickerView: View {
    @Environment(LLMService.self) private var llmService
    @Environment(ModelStore.self) private var modelStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lastModelPath") private var lastModelPath: String = ""
    @State private var showStore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                statusView
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Button("モデルストア") {
                    showStore = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("フォルダを選択...") {
                    selectModel()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .sheet(isPresented: $showStore) {
            ModelStoreView()
                .environment(modelStore)
                .environment(llmService)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch llmService.modelState {
        case .notLoaded:
            Label("モデル未選択", systemImage: "cpu")
                .foregroundStyle(.secondary)
                .font(.caption)

        case .loading:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("読み込み中...").font(.caption)
            }

        case .loaded(let name):
            Label(name, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)

        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption)
                .lineLimit(2)
        }
    }

    private func selectModel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "MLX モデルのフォルダを選択してください"
        panel.prompt = "選択"

        if panel.runModal() == .OK, let url = panel.url {
            lastModelPath = url.path
            Task {
                await llmService.loadModel(from: url)
            }
        }
    }
}
