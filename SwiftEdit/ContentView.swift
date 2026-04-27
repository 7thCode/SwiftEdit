import SwiftUI

struct ContentView: View {
    @Binding var document: SwiftEditDocument
    @Environment(LLMService.self) private var llmService
    @State private var showLLMPanel = false

    var body: some View {
        HSplitView {
            TextEditor(text: $document.text)
                .font(.system(size: 13, design: .monospaced))
                .frame(minWidth: 300, minHeight: 400)

            if showLLMPanel {
                LLMPanelView(documentText: document.text)
                    .environment(llmService)
                    .frame(minWidth: 280, idealWidth: 320)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation { showLLMPanel.toggle() }
                } label: {
                    Label("AI パネル", systemImage: showLLMPanel ? "brain.fill" : "brain")
                }
                .help(showLLMPanel ? "AI パネルを閉じる" : "AI パネルを開く")
            }
        }
    }
}
