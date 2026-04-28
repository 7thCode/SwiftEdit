import SwiftUI

@main
struct SwiftEditApp: App {
    @State private var llmService = LLMService()
    @State private var modelStore = ModelStore()

    var body: some Scene {
        DocumentGroup(newDocument: SwiftEditDocument()) { file in
            ContentView(document: file.$document)
                .environment(llmService)
                .environment(modelStore)
        }
    }
}
