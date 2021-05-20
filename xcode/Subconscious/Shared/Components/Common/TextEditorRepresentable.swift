//
//  TextEditorRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/10/21.
//

import SwiftUI

struct TextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.preferredFont(
            forTextStyle: UIFont.TextStyle.body
        )
        return textView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.text = text
    }
}

struct TextEditorRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorRepresentable(
            text: .constant("Floop")
        )
    }
}
