import SwiftUI

//struct MinimalEditorState {
//    var text: String
//}
//
//final class MinimalEditorStore: ObservableObject {
//    @Published private(set) var state: MinimalEditorState
//
//    init() {
//        self.state = MinimalEditorState(text: "")
//    }
//
//    func send(_ action: String) {
//        self.state.text = action
//    }
//}

struct MinimalEditor: View {
    @State private var text: String

    init(text: String) {
        self.text = text
    }
    
    var body: some View {
        VStack {
            Text(text)
            TextEditor(text: $text)
        }
    }
}

struct MinimalReproducibleTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        MinimalEditor(text: "Floop")
    }
}
