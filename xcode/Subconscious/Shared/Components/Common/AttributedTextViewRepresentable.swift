//
//  AttributedTextViewRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/21.
//

import SwiftUI

struct AttributedTextViewRepresentable: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        var representable: AttributedTextViewRepresentable

        init(_ representable: AttributedTextViewRepresentable) {
            self.representable = representable
        }
        
        func textViewDidChange(_ view: UITextView) {
            if representable.attributedText != view.attributedText {
                representable.attributedText = view.attributedText
                view.invalidateIntrinsicContentSize()
            }
        }
    }

    @Binding var attributedText: NSAttributedString
    var isFocused = false
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var textColor: UIColor = UIColor(.primary)
    var textContainerInset: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.translatesAutoresizingMaskIntoConstraints = false
        // Remove that extra bit of inner padding.
        // Text in view should now be flush with view edge.
        // This puts you in full control of view padding.
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        view.textColor = textColor
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if view.attributedText != attributedText {
            // Save selected range (cursor position).
            let selectedRange = view.selectedRange
            view.attributedText = attributedText
            // Restore selected range (cursor position) after setting text.
            view.selectedRange = selectedRange
        }

        if view.font != font {
            view.font = font
        }

        if view.textContainerInset != textContainerInset {
            // Set inner padding
            view.textContainerInset = textContainerInset
        }
    }

    func makeCoordinator() -> AttributedTextViewRepresentable.Coordinator {
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
}

struct AttributedTextViewRepresentablePreview: PreviewProvider {
    static var previews: some View {
        VStack {
            AttributedTextViewRepresentable(
                attributedText: .constant(NSAttributedString(string: "Text"))
            )
            .background(Constants.Color.secondaryBackground)

            AttributedTextViewRepresentable(
                attributedText: .constant(NSAttributedString(string: "Text"))
            )
            .background(Constants.Color.secondaryBackground)
        }
    }
}
