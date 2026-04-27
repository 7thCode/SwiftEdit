import SwiftUI
import AppKit

struct ModelPickerView: View {
    @Environment(LLMService.self) private var llmService
    @AppStorage("lastModelPath") private var lastModelPath: String = ""
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusView

            Button("モデルを選択...") {
                selectModel()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
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
