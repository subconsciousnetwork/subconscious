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
import Combine
import ObservableStore

//  MARK: Action
enum MarkupTextAction: Hashable, CustomLogStringConvertible {
    case requestFocus(Bool)
    case scheduleFocusChange
    case focusChange(Bool)
    case setText(String)
    case setSelection(range: NSRange, text: String)
    /// Set selection at the end of the text
    case setSelectionAtEnd

    var logDescription: String {
        switch self {
        case .setText(_):
            return "setText(...)"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Model
struct MarkupTextModel: ModelProtocol {
    var isFocusChangeScheduled = false
    var focusRequest = false
    var focus = false
    var text = ""
    var selection = NSMakeRange(0, 0)

    //  MARK: Update
    static func update(
        state: MarkupTextModel,
        action: MarkupTextAction,
        environment: Void
    ) -> Update<MarkupTextModel> {
        switch action {
        case .requestFocus(let focus):
            var model = state
            model.isFocusChangeScheduled = false
            model.focusRequest = focus
            return Update(state: model)
        case .scheduleFocusChange:
            var model = state
            model.isFocusChangeScheduled = true
            return Update(state: model)
        case .focusChange(let focus):
            var model = state
            // UI-driven focus changes always wins.
            // - Toggle off any focus change request
            // - Set desired focus to this focus
            model.isFocusChangeScheduled = false
            model.focusRequest = focus
            model.focus = focus
            return Update(state: model)
        case .setText(let text):
            var model = state
            model.text = text
            return Update(state: model)
        case .setSelection(let selection, _):
            var model = state
            model.selection = selection
            return Update(state: model)
        case .setSelectionAtEnd:
            let range = NSRange(
                state.text.endIndex...,
                in: state.text
            )
            return update(
                state: state,
                action: .setSelection(range: range, text: state.text),
                environment: ()
            )
        }
    }
}

/// A textview that grows to the height of its content
struct MarkupTextViewRepresentable: UIViewRepresentable {
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
        var representable: MarkupTextViewRepresentable

        init(
            representable: MarkupTextViewRepresentable
        ) {
            self.isUIViewUpdating = false
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
            MarkupTextViewRepresentable.logger.debug(
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
            // Return early if view is updating.
            guard !isUIViewUpdating else {
                MarkupTextViewRepresentable.logger.debug(
                    "textViewDidChange: View updating. Skipping."
                )
                return
            }
            self.representable.send(.setText(view.text))
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            // Mark focus clean
            guard !isUIViewUpdating else {
                MarkupTextViewRepresentable.logger.debug(
                    "textViewDidBeginEditing: View updating. Skipping."
                )
                return
            }
            self.representable.send(.focusChange(true))
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            guard !isUIViewUpdating else {
                MarkupTextViewRepresentable.logger.debug(
                    "textViewDidEndEditing: View updating. Skipping."
                )
                return
            }
            self.representable.send(.focusChange(false))
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
                MarkupTextViewRepresentable.logger.debug(
                    "textViewDidChangeSelection: View updating. Skipping."
                )
                return
            }
            representable.send(
                .setSelection(
                    range: textView.selectedRange,
                    text: textView.text
                )
            )
        }
    }

    static var logger = Logger(
        subsystem: Config.default.rdns,
        category: "editor"
    )

    //  MARK: Properties
    var state: MarkupTextModel
    var send: (MarkupTextAction) -> Void
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

    //  MARK: makeUIView
    func makeUIView(context: Context) -> MarkupTextView {
        Self.logger.debug("makeUIView")
        let view = MarkupTextView()

        // Coordinator is both an UITextViewDelegate
        // and an NSTextStorageDelegate.
        // Set delegate on textview (coordinator)
        view.delegate = context.coordinator
        // Set delegate on textstorage (coordinator)
        view.textStorage.delegate = context.coordinator

        // Set inner padding
        view.textContainerInset = self.textContainerInset
        // Set width (needed to calculate height based on text length)
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
    /// Note that this function gets called every time the parent of
    /// MarkupTextViewRepresentable has to recalculate its `body` property.
    ///
    /// You should think of this function as a hot loop.
    ///
    /// Avoid bashing properties that have side-effects. If you need to
    /// set a property that has side-effects, check that it is actually
    /// out of sync with the binding before setting, using an if-statement
    /// or guard.
    func updateUIView(_ view: MarkupTextView, context: Context) {
        MarkupTextViewRepresentable.logger.debug("updateUIView")
        // Set updating flag on coordinator so that event callbacks
        // can know if they are being called during an update.
        context.coordinator.isUIViewUpdating = true
        // Unset updating flag on coordator after this scope exits
        defer {
            context.coordinator.isUIViewUpdating = false
        }

        // Update text
        if view.text != state.text {
            MarkupTextViewRepresentable.logger.debug("updateUIView: set text")
            view.text = state.text
        }

        // Update width
        if view.fixedWidth != self.frame.width {
            MarkupTextViewRepresentable.logger.debug("updateUIView: set width")
            view.fixedWidth = self.frame.width
        }

        // Update view focus
        self.updateUIViewFocus(view, context: context)

        // Set selection
        if state.selection != view.selectedRange {
            MarkupTextViewRepresentable.logger.debug("updateUIView: set selection")
            view.selectedRange = self.state.selection
        }

        if self.textContainerInset != view.textContainerInset {
            MarkupTextViewRepresentable.logger.debug("updateUIView: set inset")
            // Set inner padding
            view.textContainerInset = self.textContainerInset
        }
    }

    /// If representable focus state is out of sync
    /// with `view.isFirstResponder`, then focus is dirty.
    /// Schedule first responder change in response, and
    /// flag that we are awaiting a focus change.
    /// The flag prevents us from accidentally requesting focus change
    /// more than once.
    func updateUIViewFocus(_ view: MarkupTextView, context: Context) {
        // Focus is clean, do nothing
        guard state.focus != state.focusRequest else {
            return
        }
        /// If focus change is already scheduled, return
        guard !state.isFocusChangeScheduled else {
            MarkupTextViewRepresentable.logger.debug("updateUIViewFocus: Focus is dirty but focus change already scheduled. Skipping.")
            return
        }
        send(.scheduleFocusChange)
        // Call for first responder change needs to be async,
        // or else we get an AttributeGraph cycle warning from SwiftUI.
        // This is true for both becomeFirstResponder and resignFirstResponder.
        // 2022-03-21 Gordon Brander
        DispatchQueue.main.async {
            // Check again in this tick to make sure we still need to
            // change first responder state.
            guard state.focus != state.focusRequest else {
                return
            }
            if state.focusRequest {
                MarkupTextViewRepresentable.logger.debug("async: call becomeFirstResponder")
                view.becomeFirstResponder()
            } else {
                MarkupTextViewRepresentable.logger.debug("async: call resignFirstResponder")
                view.resignFirstResponder()
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
