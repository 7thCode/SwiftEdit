import SwiftUI

@main
struct SwiftEditApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: SwiftEditDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
