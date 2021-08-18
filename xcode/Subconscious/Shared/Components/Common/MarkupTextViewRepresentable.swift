//
//  MarkupTextViewRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/21.
//

import SwiftUI

struct MarkupTextViewRepresentable: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        var representable: MarkupTextViewRepresentable

        init(_ representable: MarkupTextViewRepresentable) {
            self.representable = representable
        }
        
        func textViewDidChange(_ view: UITextView) {
            if representable.markup != view.attributedText.string {
                representable.markup = view.attributedText.string
                view.invalidateIntrinsicContentSize()
            }
        }
    }

    /// The default render function coerces the string to a plain NSAttributedString
    private static func render(_ string: String) -> NSAttributedString {
        return NSAttributedString(string: string)
    }

    @Binding var markup: String
    var render: (String) -> NSAttributedString = render
    var isFocused = false
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var textColor: UIColor = UIColor(.primary)
    var textContainerInset: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        // Remove that extra bit of inner padding.
        // Text in view should now be flush with view edge.
        // This puts you in full control of view padding.
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        view.textColor = textColor
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        let attributedText = render(markup)
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

    func makeCoordinator() -> MarkupTextViewRepresentable.Coordinator {
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
            MarkupTextViewRepresentable(
                markup: .constant("Text")
            )
            .background(Constants.Color.secondaryBackground)

            MarkupTextViewRepresentable(
                markup: .constant("Text")
            )
            .background(Constants.Color.secondaryBackground)
        }
    }
}
