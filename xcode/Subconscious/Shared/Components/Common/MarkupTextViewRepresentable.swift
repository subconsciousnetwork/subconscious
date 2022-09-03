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
enum MarkupTextAction<Focus>: Hashable
where Focus: Hashable
{
    case focus(FocusAction<Focus>)
    case requestFocus(Focus?)
    case focusChangeScheduled
    case focusChange(Focus?)
    case setText(String)
    case setSelection(NSRange)
}

//  MARK: Model
struct MarkupTextModel<Focus>: Hashable
where Focus: Hashable
{
    typealias Model = Self
    typealias Action = MarkupTextAction<Focus>

    var focus: FocusModel<Focus>
    var text = ""
    var selection = NSMakeRange(0, 0)

    //  MARK: Update
    static func update(
        state: Model,
        action: Action,
        environment: Void
    ) -> Update<Model, Action> {
        switch action {
        case .focus(let action):
            return MarkupTextFocusCursor.update(
                with: FocusModel.update,
                state: state,
                action: action,
                environment: environment
            )
        case .requestFocus(let focus):
            return requestFocus(
                state: state,
                focus: focus
            )
        case .focusChangeScheduled:
            return focusChangeScheduled(
                state: state
            )
        case .focusChange(let focus):
            return focusChange(
                state: state,
                focus: focus
            )
        case .setText(let text):
            var model = state
            model.text = text
            return Update(state: model)
        case .setSelection(let selection):
            var model = state
            model.selection = selection
            return Update(state: model)
        }
    }

    /// Handle requestFocus and send to child component
    static func requestFocus(
        state: Model,
        focus: Focus?
    ) -> Update<Model, Action> {
        let fx: Fx<Action> = Just(
            Action.focus(.requestFocus(focus))
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Handle focusChangeScheduled and send to both child components
    /// that need focus information.
    static func focusChangeScheduled(
        state: Model
    ) -> Update<Model, Action> {
        let fx: Fx<Action> = Just(
            Action.focus(.focusChangeScheduled)
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Handle focusChange and send to both child components
    /// that need focus information.
    static func focusChange(
        state: Model,
        focus: Focus?
    ) -> Update<Model, Action> {
        let fx: Fx<Action> = Just(
            Action.focus(.focusChange(focus))
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }
}

//  MARK: Cursor
//  Cursor for markup text
struct MarkupTextFocusCursor<Focus>: CursorProtocol
where Focus: Hashable
{
    typealias OuterState = MarkupTextModel<Focus>
    typealias InnerState = FocusModel<Focus>
    typealias OuterAction = MarkupTextAction<Focus>
    typealias InnerAction = FocusAction<Focus>

    static func get(state: OuterState) -> InnerState {
        state.focus
    }
    
    static func set(state: OuterState, inner: InnerState) -> OuterState {
        var model = state
        model.focus = inner
        return model
    }
    
    static func tag(action: InnerAction) -> OuterAction {
        OuterAction.focus(action)
    }
}

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
            // Return early if view is updating.
            guard !isUIViewUpdating else {
                representable.logger?.debug(
                    "textViewDidChange: View updating. Skipping."
                )
                return
            }
            self.representable.store.send(.setText(view.text))
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            // Mark focus clean
            guard !isUIViewUpdating else {
                representable.logger?.debug(
                    "textViewDidBeginEditing: View updating. Skipping."
                )
                return
            }
            self.representable.store.send(.focusChange(representable.field))
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            guard !isUIViewUpdating else {
                representable.logger?.debug(
                    "textViewDidEndEditing: View updating. Skipping."
                )
                return
            }
            self.representable.store.send(.focusChange(nil))
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
                representable.logger?.debug(
                    "textViewDidChangeSelection: View updating. Skipping."
                )
                return
            }
            representable.store.send(.setSelection(textView.selectedRange))
        }
    }

    //  MARK: Properties
    var store: ViewStore<MarkupTextModel<Focus>, MarkupTextAction<Focus>>
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
        logger?.debug("updateUIView")
        // Set updating flag on coordinator so that event callbacks
        // can know if they are being called during an update.
        context.coordinator.isUIViewUpdating = true
        // Unset updating flag on coordator after this scope exits
        defer {
            context.coordinator.isUIViewUpdating = false
        }

        // Update text
        if view.text != store.state.text {
            logger?.debug("updateUIView: set text")
            view.text = store.state.text
        }

        // Update width
        if view.fixedWidth != self.frame.width {
            logger?.debug("updateUIView: set width")
            view.fixedWidth = self.frame.width
        }

        // Update view focus
        self.updateUIViewFocus(view, context: context)

        // Set selection
        if store.state.selection != view.selectedRange {
            logger?.debug("updateUIView: set selection")
            view.selectedRange = self.store.state.selection
        }

        if self.textContainerInset != view.textContainerInset {
            logger?.debug("updateUIView: set inset")
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
        guard store.state.focus.isDirty else {
            return
        }
        /// If focus is unrelated to editor, return
        guard store.state.focus.readFocusRequestFor(field: field) != nil else {
            return
        }
        /// If focus change is already scheduled, return
        guard !store.state.focus.isScheduled else {
            logger?.debug("scheduleResignFocus: Focus is dirty but focus change already scheduled. Skipping.")
            return
        }
        store.send(.focusChangeScheduled)
        // Call for first responder change needs to be async,
        // or else we get an AttributeGraph cycle warning from SwiftUI.
        // This is true for both becomeFirstResponder and resignFirstResponder.
        // 2022-03-21 Gordon Brander
        DispatchQueue.main.async {
            // Check again in this tick to make sure we still need to
            // change first responder state.
            guard
                let isFocus = store.state.focus.readFocusRequestFor(
                    field: field
                )
            else {
                return
            }
            if isFocus {
                logger?.debug("async: call becomeFirstResponder")
                view.becomeFirstResponder()
            } else if store.state.focus.focusRequest == nil {
                logger?.debug("async: call resignFirstResponder")
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
