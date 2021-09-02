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
        override var intrinsicContentSize: CGSize {
            sizeThatFits(CGSize(width: fixedWidth, height: frame.height))
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
            representable.text = view.text
            view.invalidateIntrinsicContentSize()
            representable.onChange(view.text)
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            representable.onBeginEditing(textView.text)
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            representable.onEndEditing(textView.text)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            representable.onSelectionChange(textView.selectedRange)
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

    private static func onChangeDefault(_ text: String) -> Void {}
    private static func onBeginEditingDefault(_ text: String) -> Void {}
    private static func onEndEditingDefault(_ text: String) -> Void {}
    private static func onSelectionChangeDefault(_ range: NSRange) -> Void {}

    @Binding var text: String
    var isFocused = false
    /// Called before a text change, to determine if the text should be changed.
    var shouldChange: (
        UITextView, NSRange, String
    ) -> Bool = shouldChangeDefault
    /// Called after text has changed
    var onChange: (String) -> Void = onChangeDefault
    /// Called when textview begins editing (acquires first responder).
    var onBeginEditing: (String) -> Void = onBeginEditingDefault
    /// Called when textview ends editing (resigns first responder).
    var onEndEditing: (String) -> Void = onEndEditingDefault
    var onSelectionChange: (NSRange) -> Void = onSelectionChangeDefault
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
        if view.text != text {
            // Save selected range (cursor position).
            let selectedRange = view.selectedRange
            view.text = text
            // Restore selected range (cursor position) after setting text.
            view.selectedRange = selectedRange
        }

        if view.fixedWidth != fixedWidth {
            view.fixedWidth = fixedWidth
            view.invalidateIntrinsicContentSize()
        }

        if isFocused && !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isFocused && view.isFirstResponder {
            view.resignFirstResponder()
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
                    text: .constant("Text"),
                    fixedWidth: geometry.size.width
                )
                .fixedSize(horizontal: false, vertical: true)
                .background(Constants.Color.secondaryBackground)

                LineTextViewRepresentable(
                    text: .constant("Text"),
                    fixedWidth: geometry.size.width
                )
                .fixedSize(horizontal: false, vertical: true)
                .background(Constants.Color.secondaryBackground)
            }
        }
    }
}
