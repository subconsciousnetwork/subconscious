//
//  TextViewRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/21.
//

import SwiftUI

struct TextViewRepresentable: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        var representable: TextViewRepresentable

        init(_ representable: TextViewRepresentable) {
            self.representable = representable
        }
        
        func textViewDidChange(_ view: UITextView) {
            representable.text = view.text
        }
    }
    
    private var isFocused = false
    private var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    private var textContainerInset: UIEdgeInsets = .zero
    @Binding var text: String

    init(
        text: Binding<String>
    ) {
        self._text = text
    }
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.text = text
        view.font = font
        // Set inner padding
        view.textContainerInset = textContainerInset
        // Remove that last bit of inner padding.
        // Text in view should now be flush with view edge.
        // This puts you in full control of view padding.
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        
        if isFocused {
            view.becomeFirstResponder()
        } else {
            view.resignFirstResponder()
        }
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if view.text != text {
            view.text = text
        }

        if view.font != font {
            view.font = font
        }

        if view.textContainerInset != textContainerInset {
            view.textContainerInset = textContainerInset
        }

        if isFocused {
            view.becomeFirstResponder()
        } else {
            view.resignFirstResponder()
        }
    }

    func makeCoordinator() -> TextViewRepresentable.Coordinator {
        Coordinator(self)
    }
    
    func font(_ font: UIFont) -> Self {
        var view = self
        view.font = font
        return view
    }

    func insets(_ inset: EdgeInsets) -> Self {
        var view = self
        view.textContainerInset = UIEdgeInsets(
            top: inset.top,
            left: inset.leading,
            bottom: inset.bottom,
            right: inset.trailing
        )
        return view
    }
    
    /// Focus view
    func focused(_ isFocused: Bool) -> Self {
        var view = self
        view.isFocused = isFocused
        return view
    }
}

struct TextViewRepresentablePreview: PreviewProvider {
    static var previews: some View {
        VStack {
            TextViewRepresentable(
                text: .constant("Text")
            )
        }
    }
}
