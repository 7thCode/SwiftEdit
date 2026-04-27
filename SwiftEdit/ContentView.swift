import SwiftUI

struct ContentView: View {
    @Binding var document: SwiftEditDocument

    var body: some View {
        TextEditor(text: $document.text)
            .font(.system(size: 13, design: .monospaced))
            .frame(minWidth: 500, minHeight: 400)
    }
}
