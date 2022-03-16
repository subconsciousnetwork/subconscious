//
//  MarkupTextViewRepresenable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/21.
//
//  Note: we used to expose a way to set the `UITextView.font` property.
//
//  DO NOT SET `UITextView.font` property when using attributedText!
//  It is meant for when you use `UITextView.text` without attributes.
//  Setting it WHILE setting `attributedText` causes multiple issues:
//
//  - Styling properties will be overwritten by attributes given to
//    `.font`. They seem to be applied after
//    assigning `attributedText`.
//  - You can create accidental feedback loops between the event
//    delegate and the representable. This is because when you set
//    attributedText on the UITextView, the attributed set on the
//    property will no longer be equal to the attributedText before
//    setting, since the font properties will be appended, modifying
//    the attributes.
//
//  Lesson learned.
//  2021-10-04 Gordon Brander

import SwiftUI

/// A type that can be parsed from string via `init(markup: String)`,
/// and rendered to an NSAttributedString via `render()`.
protocol MarkupConvertable {
    init(markup: String)
    func render() -> NSAttributedString
}

/// A textview that grows to the height of its content
struct MarkupTextViewRepresenable<Focus, Dom>: UIViewRepresentable
where
    Focus: Hashable,
    Dom: Equatable,
    Dom: MarkupConvertable
{
    //  MARK: TextStorage subclass
    /// TextStorage subclass responsible for rendering DOM to attributes.
    ///
    /// Our subclass uses a `attributedString`, an `NSMutableString` to
    /// store our text data. Overrides to key methods make changes to this
    /// mutable attributed string.
    ///
    /// See wiki for notes:
    /// https://github.com/gordonbrander/subconscious/wiki/TextKit
    ///
    /// Related issue:
    /// https://github.com/gordonbrander/subconscious/issues/211
    class MarkupTextStorage: NSTextStorage {
        /// The backing store in which we keep text data.
        /// Subclasses of NSTextStorage are responsible for providing their
        /// own backing store.
        let attributedString = NSMutableAttributedString()

        /// Defer to our backing store string for this attribute
        override var string: String {
            return attributedString.string
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        /// Defer to our backing store string for attributes
        override func attributes(
            at location: Int,
            effectiveRange range: NSRangePointer?
        ) -> [NSAttributedString.Key: Any] {
            attributedString.attributes(
                at: location,
                effectiveRange: range
            )
        }

        /// Replace characters on our backing store
        override func replaceCharacters(in range: NSRange, with str: String) {
            // We use the (required) text storage lifecycle methods to
            // notify the associated layout manager when making edits.
            // Start a text editing transaction
            beginEditing()
            // Update our backing store
            attributedString.replaceCharacters(in: range, with:str)
            // Mark what was edited
            edited(
                .editedCharacters,
                range: range,
                changeInLength: (str as NSString).length - range.length
            )
            // End editing transaction
            endEditing()
        }

        /// Set attributes on our backing store
        override func setAttributes(
            _ attrs: [NSAttributedString.Key: Any]?,
            range: NSRange
        ) {
            // We use the (required) text storage lifecycle methods to
            // notify the associated layout manager when making edits.
            // Start a text editing transaction
            beginEditing()
            // Update our backing store
            attributedString.setAttributes(attrs, range: range)
            // Mark what was edited
            edited(.editedAttributes, range: range, changeInLength: 0)
            // End editing transaction
            endEditing()
        }
    }

    //  MARK: UITextView subclass
    class FixedWidthTextView: UITextView {
        var fixedWidth: CGFloat = 0
        override var intrinsicContentSize: CGSize {
            sizeThatFits(
                CGSize(
                    width: fixedWidth,
                    height: frame.height
                )
            )
        }
    }

    //  MARK: Coordinator
    class Coordinator: NSObject, UITextViewDelegate {
        /// Is event happening during updateUIView?
        /// Used to avoid sending up events that would cause feedback cycles where an update triggers
        /// an event, which triggers an update, which triggers an event, etc.
        var isUIViewUpdating: Bool
        var representable: MarkupTextViewRepresenable

        init(_ representable: MarkupTextViewRepresenable) {
            self.isUIViewUpdating = false
            self.representable = representable
        }

        /// Handle link taps
        func textView(
            _ textView: UITextView,
            shouldInteractWith url: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool {
            representable.onLink(
                url,
                textView.attributedText,
                characterRange,
                interaction
            )
        }

        /// Render user changes to textview
        func textViewDidChange(_ view: UITextView) {
            // Return early if view is updating.
            guard !isUIViewUpdating else {
                return
            }
            let dom = Dom(markup: view.attributedText.string)
            if representable.dom != dom {
                let selectedRange = view.selectedRange
                view.attributedText = dom.render()
                view.selectedRange = selectedRange
                view.invalidateIntrinsicContentSize()
                representable.dom = dom
            }
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            representable.focus = representable.field
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            // Un-focus editor if it still has focus.
            // If some other field has already taken focus, leave
            // it alone.
            if representable.focus == representable.field {
                representable.focus = nil
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Return early if view is currently updating.
            // We set selection during update when updating
            // attributedText, in order to retain selection.
            // Do not set representable selection in this case. It would
            // generate an update feedback loop, since the direction of
            // mutation goes from representable to view during an update.
            // 2021-10-06 Gordon Brander
            guard !isUIViewUpdating else {
                return
            }
            if textView.selectedRange != representable.selection {
                representable.selection = textView.selectedRange
            }
        }
    }

    /// Default handler for link clicks. Always defers to OS-level handler.
    private static func onLinkDefault(
        url: URL,
        attributedText: NSAttributedString,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        return true
    }

    //  MARK: Properties
    @Binding var dom: Dom
    @Binding var selection: NSRange
    @Binding var focus: Focus?
    var field: Focus
    var fixedWidth: CGFloat
    var textColor: UIColor = UIColor(.primary)
    var textContainerInset: UIEdgeInsets = .zero
    /// Fixed width of textview container, needed to determine textview height.
    /// Use `GeometryView` to find container width.
    var onLink: (
        URL,
        NSAttributedString,
        NSRange,
        UITextItemInteraction
    ) -> Bool = onLinkDefault

    /// Is this field is currently focused?
    private var isFocused: Bool {
        focus == field
    }

    //  MARK: makeUIView
    func makeUIView(context: Context) -> FixedWidthTextView {
        let view = FixedWidthTextView()
        view.delegate = context.coordinator
        view.fixedWidth = context.coordinator.representable.fixedWidth
        // Remove that extra bit of inner padding.
        // Text in view should now be flush with view edge.
        // This puts you in full control of view padding.
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        view.textColor = textColor
        view.isScrollEnabled = false
        return view
    }

    //  MARK: updateUIView
    func updateUIView(_ view: FixedWidthTextView, context: Context) {
        // Set updating flag on coordinator
        context.coordinator.isUIViewUpdating = true
        // Unset updating flag on coordator after this scope exits
        defer {
            context.coordinator.isUIViewUpdating = false
        }

        let attributedText = self.dom.render()
        if !view.attributedText.isEqual(to: attributedText) {
            // Save selected range (cursor position).
            let selectedRange = view.selectedRange
            view.attributedText = attributedText
            // Restore selected range (cursor position) after setting text.
            view.selectedRange = selectedRange
            view.invalidateIntrinsicContentSize()
        }

        if fixedWidth != view.fixedWidth {
            view.fixedWidth = fixedWidth
            view.invalidateIntrinsicContentSize()
        }

        // Set firstResponder
        if isFocused != view.isFirstResponder {
            if isFocused {
                DispatchQueue.main.async {
                    view.becomeFirstResponder()
                }
            } else {
                DispatchQueue.main.async {
                    view.resignFirstResponder()
                }
            }
        }

        // Set selection
        if selection != view.selectedRange {
            view.selectedRange = selection
        }

        if textContainerInset != view.textContainerInset {
            // Set inner padding
            view.textContainerInset = textContainerInset
        }
    }

    func makeCoordinator() -> Self.Coordinator {
        Coordinator(self)
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
