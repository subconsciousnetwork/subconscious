//
//  LineTextViewRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/21.
//

import SwiftUI

/// A textview that grows to the height of its content
struct LineTextViewRepresentable: UIViewRepresentable {
    /// Extends UITTextView to provide an intrinsicContentSize given a fixed width.
    class FixedWidthTextView: UITextView {
        var fixedWidth: CGFloat = 0
        var minHeight: CGFloat = 300
        override var intrinsicContentSize: CGSize {
            sizeThatFits(
                CGSize(
                    width: fixedWidth,
                    height: max(frame.height, minHeight)
                )
            )
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var representable: LineTextViewRepresentable

        init(_ representable: LineTextViewRepresentable) {
            self.representable = representable
        }

        /// Intercept text changes before they happen, and accept or reject them.
        /// See  <https://developer.apple.com/documentation/uikit/uitextviewdelegate/1618630-textview>
        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            representable.shouldChange(
                textView,
                range,
                text
            )
        }

        /// Handle changes to textview
        func textViewDidChange(_ view: UITextView) {
            representable.attributedText = view.attributedText
            view.invalidateIntrinsicContentSize()
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            representable.isFocused = true
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            representable.isFocused = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            representable.selection = textView.selectedRange
        }
    }

    /// Defalult no-op event handlers
    private static func shouldChangeDefault(
        view: UITextView,
        selection: NSRange,
        text: String
    ) -> Bool {
        return true
    }

    @Binding var attributedText: NSAttributedString
    @Binding var isFocused: Bool
    @Binding var selection: NSRange
    /// Called before a text change, to determine if the text should be changed.
    var shouldChange: (
        UITextView, NSRange, String
    ) -> Bool = shouldChangeDefault
    /// Fixed width of textview container, needed to determine textview height.
    /// Use `GeometryView` to find container width.
    var fixedWidth: CGFloat
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var textColor: UIColor = UIColor(.primary)
    var textContainerInset: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> FixedWidthTextView {
        let view = FixedWidthTextView()
        view.delegate = context.coordinator
        view.fixedWidth = fixedWidth
        // Remove that extra bit of inner padding.
        // Text in view should now be flush with view edge.
        // This puts you in full control of view padding.
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        view.textColor = textColor
        return view
    }

    func updateUIView(_ view: FixedWidthTextView, context: Context) {
        if !view.attributedText.isEqual(to: attributedText) {
            // Save selected range (cursor position).
            let selectedRange = view.selectedRange
            view.attributedText = attributedText
            // Restore selected range (cursor position) after setting text.
            view.selectedRange = selectedRange
        }

        if view.fixedWidth != fixedWidth {
            view.fixedWidth = fixedWidth
            view.invalidateIntrinsicContentSize()
        }

        // Set firstResponder
        if isFocused && !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isFocused && view.isFirstResponder {
            view.resignFirstResponder()
        }

        // Set selection
        if selection != view.selectedRange {
            view.selectedRange = selection
        }

        if view.font != font {
            view.font = font
        }

        if view.textContainerInset != textContainerInset {
            // Set inner padding
            view.textContainerInset = textContainerInset
        }
    }

    func makeCoordinator() -> LineTextViewRepresentable.Coordinator {
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

struct LineTextViewRepresentable_Preview: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            VStack {
                LineTextViewRepresentable(
                    attributedText: .constant(NSAttributedString("Text")),
                    isFocused: .constant(true),
                    selection: .constant(NSRange.zero),
                    fixedWidth: geometry.size.width
                )
                .fixedSize(horizontal: false, vertical: true)
                .background(Constants.Color.secondaryBackground)

                LineTextViewRepresentable(
                    attributedText: .constant(NSAttributedString("Text")),
                    isFocused: .constant(false),
                    selection: .constant(NSRange.zero),
                    fixedWidth: geometry.size.width
                )
                .fixedSize(horizontal: false, vertical: true)
                .background(Constants.Color.secondaryBackground)
            }
        }
    }
}
