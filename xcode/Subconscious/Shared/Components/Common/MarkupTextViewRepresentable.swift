//
//  MarkupTextViewRepresentable.swift
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
//
//  We now render text properties via an `NSTextStorageDelegate`.
//  All styling is derived from markup. You should never have to set styling
//  on the UITextView yourself when consuming this view.
//  See https://github.com/gordonbrander/subconscious/pull/220/
//  See https://github.com/gordonbrander/subconscious/issues/211
//  2022-03-17 Gordon Brander

import SwiftUI

/// A textview that grows to the height of its content
struct MarkupTextViewRepresentable<Focus>: UIViewRepresentable
where Focus: Hashable
{
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
    class Coordinator: NSObject, UITextViewDelegate, NSTextStorageDelegate {
        /// Is event happening during updateUIView?
        /// Used to avoid sending up events that would cause feedback cycles
        /// where an update triggers an event, which triggers an update,
        /// which triggers an event, etc.
        var isUIViewUpdating: Bool
        var representable: MarkupTextViewRepresentable
        /// Records the last known focus state.
        /// Used as a dirty flag to prevent aggressive calling of
        /// first responder methods during view update.
        var didFocus: Focus?

        init(
            representable: MarkupTextViewRepresentable
        ) {
            self.isUIViewUpdating = false
            self.representable = representable
            self.didFocus = representable.focus
        }

        /// NSTextStorageDelegate method
        /// Handle markup rendering, just before processEditing is fired.
        /// It is important that we render markup in `willProcessEditing`
        /// because it happens BEFORE font substitution. Rendering before font
        /// substitution gives the OS a chance to replace fonts for things like
        /// Emoji or Unicode characters when your font does not support them.
        /// See:
        /// https://github.com/gordonbrander/subconscious/wiki/nstextstorage-font-substitution-and-missing-text
        ///
        /// 2022-03-17 Gordon Brander
        func textStorage(
            _ textStorage: NSTextStorage,
            willProcessEditing: NSTextStorage.EditActions,
            range: NSRange,
            changeInLength: Int
        ) {
            textStorage.setAttributes(
                [:],
                range: NSRange(
                    textStorage.string.startIndex...,
                    in: textStorage.string
                )
            )
            // Render markup on TextStorage (which is an NSMutableString)
            // using closure set on view (representable)
            self.representable.renderAttributesOf(textStorage)
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
            print("textViewDidChange")
            // Return early if view is updating.
            guard !isUIViewUpdating else {
                return
            }
            if representable.text != view.text {
                let selectedRange = view.selectedRange
                view.selectedRange = selectedRange
                view.invalidateIntrinsicContentSize()
                representable.text = view.text
            }
        }

        func setFocus(_ field: Focus?) {
            self.didFocus = field
            if representable.focus != field {
                representable.focus = field
            }
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            guard !isUIViewUpdating else {
                return
            }
            self.setFocus(representable.field)
            print("textViewDidBeginEditing", self.didFocus, representable.focus)
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            guard !isUIViewUpdating else {
                return
            }
            self.setFocus(nil)
            print("textViewDidEndEditing", self.didFocus, representable.focus)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Return early if view is currently updating.
            // We set selection during update when updating
            // text, in order to retain selection.
            // Do not set representable selection in this case. It would
            // generate an update feedback loop, since the direction of
            // mutation goes from representable to view during an update.
            // 2021-10-06 Gordon Brander
            guard !isUIViewUpdating else {
                return
            }
            if textView.selectedRange != representable.selection {
                representable.$selection.wrappedValue = textView.selectedRange
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
    @Binding var text: String
    @Binding var selection: NSRange
    @Binding var focus: Focus?
    var field: Focus
    /// Frame needed to determine textview height.
    /// Use `GeometryView` to find container width.
    var frame: CGRect
    var textColor: UIColor = UIColor(.primary)
    var textContainerInset: UIEdgeInsets = .zero
    /// Function to render NSAttributedString attributes from a markup string.
    /// The renderer will use these attributes to style the string.
    var renderAttributesOf: (NSMutableAttributedString) -> Void
    var onLink: (
        URL,
        NSAttributedString,
        NSRange,
        UITextItemInteraction
    ) -> Bool = onLinkDefault

    //  MARK: makeUIView
    func makeUIView(context: Context) -> FixedWidthTextView {
        let view = FixedWidthTextView()

        // Coordinator is both an UITextViewDelegate
        // and an NSTextStorageDelegate.
        // Set delegate on textview (coordinator)
        view.delegate = context.coordinator
        // Set delegate on textstorage (coordinator)
        view.textStorage.delegate = context.coordinator

        view.fixedWidth = self.frame.width
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
        print("updateUIView", context.coordinator.didFocus, self.focus)
        // Set updating flag on coordinator
        context.coordinator.isUIViewUpdating = true
        // Unset updating flag on coordator after this scope exits
        defer {
            context.coordinator.isUIViewUpdating = false
        }

        if view.text != self.text {
            // Save selected range (cursor position).
            let selectedRange = view.selectedRange
            view.text = self.text
            // Restore selected range (cursor position) after setting text.
            view.selectedRange = selectedRange
            view.invalidateIntrinsicContentSize()
        }

        if view.fixedWidth != self.frame.width {
            view.fixedWidth = self.frame.width
            view.invalidateIntrinsicContentSize()
        }

        // Set firstResponder
        if context.coordinator.didFocus != self.focus {
            print("context.coordinator.didFocus != self.focus", context.coordinator.didFocus, self.focus)
            DispatchQueue.main.async {
                print("DispatchQueue.main.async", context.coordinator.didFocus, self.focus)
                if context.coordinator.didFocus != self.focus {
                    if self.focus == field {
                        view.becomeFirstResponder()
                    } else {
                        view.resignFirstResponder()
                    }
                }
            }
        }

        // Set selection
        if self.selection != view.selectedRange {
            view.selectedRange = self.selection
        }

        if self.textContainerInset != view.textContainerInset {
            // Set inner padding
            view.textContainerInset = self.textContainerInset
        }
    }

    func makeCoordinator() -> Self.Coordinator {
        Coordinator(
            representable: self
        )
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
