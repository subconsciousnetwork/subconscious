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
            // If user hit enter
            if range.length == 0 && text == "\n" {
                textView.resignFirstResponder()
                representable.onEnter()
                return false
            // If user pasted text containing newline
            } else if text.contains("\n") {
                let clean = text.replacingOccurrences(
                    of: "\n",
                    with: " "
                )
                if let range = Range(range, in: textView.text) {
                    textView.text.replaceSubrange(range, with: clean)
                    textView.invalidateIntrinsicContentSize()
                    return false
                }
                return true
            }
            return true
        }

        /// Handle changes to textview
        func textViewDidChange(_ view: UITextView) {
            representable.text = view.text
            view.invalidateIntrinsicContentSize()
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            representable.onEditingChange(true)
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            representable.onEditingChange(false)
        }
    }

    /// Defalult no-op event handlers
    private static func onEnter() -> Void {}
    private static func onEditingChange(
        _ isEditing: Bool
    ) -> Void {}

    @Binding var text: String
    /// Called when user hits enter, or tries to create a line break.
    var onEnter: () -> Void = onEnter
    /// Called when textview begins or ends editing.
    /// Callback is passed a boolean that flags if textview is being edited.
    var onEditingChange: (Bool) -> Void = onEditingChange
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
