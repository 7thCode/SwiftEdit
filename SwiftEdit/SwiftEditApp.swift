import SwiftUI

@main
struct SwiftEditApp: App {
    @State private var llmService = LLMService()

    var body: some Scene {
        DocumentGroup(newDocument: SwiftEditDocument()) { file in
            ContentView(document: file.$document)
                .environment(llmService)
        }
    }
}
