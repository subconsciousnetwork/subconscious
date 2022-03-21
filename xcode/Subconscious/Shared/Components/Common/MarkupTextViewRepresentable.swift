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
import os
import SwiftUI

/// A textview that grows to the height of its content
struct MarkupTextViewRepresentable<Focus>: UIViewRepresentable
where Focus: Hashable
{
    //  MARK: UITextView subclass
    class MarkupTextView: UITextView {
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
        /// Used to avoid setting properties in events during view updates, as
        /// that would cause feedback cycles where an update triggers an event,
        /// which triggers an update, which triggers an event, etc.
        var isUIViewUpdating: Bool
        // Dirty flag signaling if focus change has been requested already
        var isAwaitingFocusChange: Bool
        var representable: MarkupTextViewRepresentable

        init(
            representable: MarkupTextViewRepresentable
        ) {
            self.isUIViewUpdating = false
            self.isAwaitingFocusChange = false
            self.representable = representable
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
            representable.logger?.debug(
                "textStorage: render markup attributes"
            )
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
            representable.logger?.debug(
                "textViewDidChange"
            )
            // Return early if view is updating.
            guard !isUIViewUpdating else {
                representable.logger?.debug(
                    "textViewDidChange: View updating. Skipping."
                )
                return
            }
            if representable.text != view.text {
                representable.logger?.debug(
                    "textViewDidChange: set text binding"
                )
                representable.text = view.text
                view.invalidateIntrinsicContentSize()
            }
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            representable.logger?.debug("textViewDidBeginEditing")
            // Mark focus clean
            guard !isUIViewUpdating else {
                representable.logger?.debug(
                    "textViewDidBeginEditing: View updating. Skipping."
                )
                return
            }
            // Set dirty flag to false and
            // Sync representable focus binding state to textview state.
            self.isAwaitingFocusChange = false
            if representable.focus != representable.field {
                representable.logger?.debug(
                    "textViewDidBeginEditing: set focus binding to focused state."
                )
                representable.focus = representable.field
            }
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            representable.logger?.debug("textViewDidEndEditing")
            // Mark focus clean
            self.isAwaitingFocusChange = false
            guard !isUIViewUpdating else {
                representable.logger?.debug(
                    "textViewDidEndEditing: View updating. Skipping."
                )
                return
            }
            if representable.focus == representable.field {
                representable.logger?.debug(
                    "textViewDidEndEditing: set focus binding to nil."
                )
                representable.focus = nil
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            representable.logger?.debug("textViewDidChangeSelection")
            // Return early if view is currently updating.
            // We set selection during update when updating
            // text, in order to retain selection.
            // Do not set representable selection in this case. It would
            // generate an update feedback loop, since the direction of
            // mutation goes from representable to view during an update.
            // 2021-10-06 Gordon Brander
            guard !isUIViewUpdating else {
                representable.logger?.debug(
                    "textViewDidChangeSelection: View updating. Skipping."
                )
                return
            }
            if textView.selectedRange != representable.selection {
                representable.logger?.debug(
                    "textViewDidChangeSelection: set selection binding."
                )
                representable.$selection.wrappedValue = textView.selectedRange
            }
        }
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
    ) -> Bool
    var logger: Logger?

    var isFocused: Bool {
        self.focus == field
    }

    //  MARK: makeUIView
    func makeUIView(context: Context) -> MarkupTextView {
        logger?.debug("makeUIView")
        let view = MarkupTextView()

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
    func updateUIView(_ view: MarkupTextView, context: Context) {
        logger?.debug("updateUIView")
        // Set updating flag on coordinator
        context.coordinator.isUIViewUpdating = true
        // Unset updating flag on coordator after this scope exits
        defer {
            context.coordinator.isUIViewUpdating = false
        }

        // Update text
        self.updateUIViewText(view, context: context)

        // Update width
        if view.fixedWidth != self.frame.width {
            logger?.debug("updateUIView: set width")
            view.fixedWidth = self.frame.width
            view.invalidateIntrinsicContentSize()
        }

        // Update view focus
        self.updateUIViewFocus(view, context: context)

        // Set selection
        if self.selection != view.selectedRange {
            logger?.debug("updateUIView: set selection")
            view.selectedRange = self.selection
        }

        if self.textContainerInset != view.textContainerInset {
            logger?.debug("updateUIView: set inset")
            // Set inner padding
            view.textContainerInset = self.textContainerInset
        }
    }

    /// Update UIView text state farom binding if necessary
    /// Also invalidates intrinsic content size so that text view can
    /// grow to contain new text contents.
    func updateUIViewText(_ view: MarkupTextView, context: Context) {
        guard view.text != self.text else {
            return
        }
        logger?.debug("updateUIView: set text")
        // Save selected range (cursor position).
        let selectedRange = view.selectedRange
        view.text = self.text
        // Restore selected range (cursor position) after setting text.
        view.selectedRange = selectedRange
        view.invalidateIntrinsicContentSize()
    }

    /// If representable focus state is out of sync
    /// with `view.isFirstResponder`, then focus is dirty.
    /// Schedule first responder change in response, and
    /// flag that we are awaiting a focus change.
    /// The flag prevents us from accidentally requesting focus change
    /// more than once.
    func updateUIViewFocus(_ view: MarkupTextView, context: Context) {
        // Focus is clean, do nothing
        guard isFocused != view.isFirstResponder else {
            return
        }
        guard !context.coordinator.isAwaitingFocusChange else {
            logger?.debug(
                "updateUIViewFocus: Focus is dirty but focus change already scheduled. Skipping."
            )
            return
        }
        context.coordinator.isAwaitingFocusChange = true
        logger?.debug(
            "updateUIViewFocus: Focus is dirty. Scheduling focus change."
        )
        // Call for first responder change needs to be async,
        // or else we get an AttributeCycle warning from SwiftUI.
        // 2022-03-21 Gordon Brander
        DispatchQueue.main.async {
            // Check again in this tick to make sure we still need to
            // request first responder change.
            if isFocused != view.isFirstResponder {
                if isFocused {
                    logger?.debug(
                        "async: call becomeFirstResponder"
                    )
                    view.becomeFirstResponder()
                } else {
                    logger?.debug(
                        "async: call resignFirstResponder"
                    )
                    view.resignFirstResponder()
                }
            }
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
