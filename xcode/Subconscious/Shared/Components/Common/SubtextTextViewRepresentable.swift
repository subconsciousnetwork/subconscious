//
//  SubtextTextViewRepresentable.swift
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

// MARK: Action
enum SubtextTextAction: Hashable {
    case requestFocus(Bool)
    case scheduleFocusChange
    case focusChange(Bool)
    case setText(String)
    case setSelection(range: NSRange, text: String)
    /// Set selection at the end of the text
    case setSelectionAtEnd
    case setSelectionAtStart
    case setEditable(Bool)
}

// MARK: Model
struct SubtextTextModel: ModelProtocol {
    var isFocusChangeScheduled = false
    var focusRequest = false
    var focus = false
    var text = ""
    var selection = NSMakeRange(0, 0)
    var isEditable = true

    // MARK: Update
    static func update(
        state: Self,
        action: SubtextTextAction,
        environment: Void
    ) -> Update<Self> {
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
        case .setSelectionAtStart:
            let range = NSRange(location: 0, length: 0)
            return update(
                state: state,
                action: .setSelection(range: range, text: state.text),
                environment: ()
            )
        case .setEditable(let isEditable):
            var model = state
            model.isEditable = isEditable
            return Update(state: model)
        }
    }
}

/// A textview that grows to the height of its content
struct SubtextTextViewRepresentable: UIViewRepresentable {
    // MARK: UITextView subclass
    class SubtextTextView: UITextView {
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

    // MARK: Coordinator
    class Coordinator:
        NSObject,
        UITextViewDelegate,
        NSTextContentStorageDelegate,
        NSTextStorageDelegate,
        NSTextContentManagerDelegate
    {
        /// Is event happening during updateUIView?
        /// Used to avoid setting properties in events during view updates, as
        /// that would cause feedback cycles where an update triggers an event,
        /// which triggers an update, which triggers an event, etc.
        var isUIViewUpdating: Bool
        var representable: SubtextTextViewRepresentable
        var suspendTextRendering: Bool = false
        var renderTranscludeBlocks: Bool = false
        /// Subtext renderer instance
        var renderer: SubtextAttributedStringRenderer
        var subtext: Subtext? = nil
        
        init(
            representable: SubtextTextViewRepresentable
        ) {
            self.isUIViewUpdating = false
            self.representable = representable
            self.renderer = SubtextAttributedStringRenderer()
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
            SubtextTextViewRepresentable.logger.debug(
              "textStorage: render markup attributes"
            )

            // Render markup on TextStorage (which is an NSMutableString)
            self.subtext = renderer.renderAttributesOf(textStorage)
        }

        /// Handle link taps
        func textView(
            _ textView: UITextView,
            primaryActionFor textItem: UITextItem,
            defaultAction: UIAction
        ) -> UIAction? {
            if case .link(let url) = textItem.content {
                let shouldDeferToDefault = representable.onLink(url)
                return shouldDeferToDefault ? defaultAction : .none
            }
            return defaultAction
        }

        /// Render user changes to textview
        func textViewDidChange(_ view: UITextView) {
            // Return early if view is updating.
            guard !isUIViewUpdating else {
                SubtextTextViewRepresentable.logger.debug(
                    "textViewDidChange: View updating. Skipping."
                )
                return
            }
            
            // Since this change originated from within the UITextView
            // we can safely suppress re-renders.
            // We're passing view.text in so there's no need to re-set it.
            self.suspendTextRendering = true
            self.representable.send(.setText(view.text))
            self.suspendTextRendering = false
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            // Mark focus clean
            guard !isUIViewUpdating else {
                SubtextTextViewRepresentable.logger.debug(
                    "textViewDidBeginEditing: View updating. Skipping."
                )
                return
            }
            self.representable.send(.focusChange(true))
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            guard !isUIViewUpdating else {
                SubtextTextViewRepresentable.logger.debug(
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
                SubtextTextViewRepresentable.logger.debug(
                    "textViewDidChangeSelection: View updating. Skipping."
                )
                return
            }
            
            // Since this change originated from within the UITextView
            // we can safely suppress re-renders.
            // We're passing view.text in so there's no need to re-set it.
            self.suspendTextRendering = true
            representable.send(
                .setSelection(
                    range: textView.selectedRange,
                    text: textView.text
                )
            )
            self.suspendTextRendering = false
        }
    }

    static var logger = Logger(
        subsystem: Config.default.rdns,
        category: "SubtextTextViewRepresentable"
    )

    // MARK: Properties
    @ScaledMetric(relativeTo: .body)
    private var bodySize: CGFloat = AppTheme.textSize
    
    var state: SubtextTextModel
    var send: (SubtextTextAction) -> Void
    /// Frame needed to determine textview height.
    /// Use `GeometryView` to find container width.
    var frame: CGRect
    var textColor: UIColor = UIColor(.primary)
    var textContainerInset: UIEdgeInsets = .zero
    var onLink: (URL) -> Bool
    
    // MARK: makeUIView
    func makeUIView(context: Context) -> SubtextTextView {
        Self.logger.debug("makeUIView")
        
        // Coordinator acts as all the relevant delegates
        let textLayoutManager = NSTextLayoutManager()
        let textContentStorage = NSTextContentStorage()
        let textContainer = NSTextContainer()
        textContentStorage.delegate = context.coordinator
        textContentStorage.addTextLayoutManager(textLayoutManager)
        textLayoutManager.textContainer = textContainer
        
        let view = SubtextTextView(frame: self.frame, textContainer: textContainer)
        view.delegate = context.coordinator
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
        view.isEditable = state.isEditable
        // Tell UITextView to automatically adjust font size based on
        // system font size
        view.adjustsFontForContentSizeCategory = true
        return view
    }

    // MARK: updateUIView
    /// Note that this function gets called every time the parent of
    /// SubtextViewRepresentable has to recalculate its `body` property.
    ///
    /// You should think of this function as a hot loop.
    ///
    /// Avoid bashing properties that have side-effects. If you need to
    /// set a property that has side-effects, check that it is actually
    /// out of sync with the binding before setting, using an if-statement
    /// or guard.
    func updateUIView(_ view: SubtextTextView, context: Context) {
        SubtextTextViewRepresentable.logger.debug("updateUIView")
        // Set updating flag on coordinator so that event callbacks
        // can know if they are being called during an update.
        context.coordinator.isUIViewUpdating = true
        // Unset updating flag on coordator after this scope exits
        defer {
            context.coordinator.isUIViewUpdating = false
        }

        // When a key is pressed, updateUIView is called multiple times. The first time, state has
        // not yet been updated to hold the latest text BUT view.text has already updated.
        // This can result in thrashing the TextView and killing performance.
        
        // Pathological scenario:
        // state.text = "abc"
        // view.text = "abc"
        // > user types "d"
        // view.text = "abcd"
        // updateUIView() called
        // we set view.text = state.text
        // now, view.text = "abc"
        // THEN state.text updates to "abcd"
        // updateUIVIew() called again
        // we set view.text = state.text
        // view.text = "abcd"
        
        // so we set view.text TWICE when we could set it zero times
        // caching the last known rendered value allows us to detect and sidestep this scenario
        if view.text != state.text && !context.coordinator.suspendTextRendering {
            view.text = state.text
        }

        // Update width
        if view.fixedWidth != self.frame.width {
            SubtextTextViewRepresentable.logger.debug("updateUIView: set width")
            view.fixedWidth = self.frame.width
        }

        // Update view focus
        self.updateUIViewFocus(view, context: context)

        // Set selection
        if state.selection != view.selectedRange {
            SubtextTextViewRepresentable.logger.debug("updateUIView: set selection")
            view.selectedRange = self.state.selection
        }

        if self.textContainerInset != view.textContainerInset {
            SubtextTextViewRepresentable.logger.debug("updateUIView: set inset")
            // Set inner padding
            view.textContainerInset = self.textContainerInset
        }

        if view.isEditable != self.state.isEditable {
            view.isEditable = self.state.isEditable
        }
    }

    /// If representable focus state is out of sync
    /// with `view.isFirstResponder`, then focus is dirty.
    /// Schedule first responder change in response, and
    /// flag that we are awaiting a focus change.
    /// The flag prevents us from accidentally requesting focus change
    /// more than once.
    func updateUIViewFocus(_ view: SubtextTextView, context: Context) {
        // Focus is clean, do nothing
        guard state.focus != state.focusRequest else {
            return
        }
        /// If focus change is already scheduled, return
        guard !state.isFocusChangeScheduled else {
            SubtextTextViewRepresentable.logger.debug("updateUIViewFocus: Focus is dirty but focus change already scheduled. Skipping.")
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
                SubtextTextViewRepresentable.logger.debug("async: call becomeFirstResponder")
                view.becomeFirstResponder()
            } else {
                SubtextTextViewRepresentable.logger.debug("async: call resignFirstResponder")
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

extension Subtext {
    func block(forParagraph: NSTextParagraph) -> Block? {
        return blocks.last { b in
            guard let contentRange = forParagraph.paragraphContentRange else {
                return false
            }
            guard let textContentStorage = forParagraph.textContentManager as? NSTextContentStorage else {
                return false
            }
            
            // Is this instance of Subtext actually working on the same text that the paragraph belongs to?
            guard let underlyingString = textContentStorage.attributedString?.string else {
                return false
            }
            guard underlyingString == base else {
                return false
            }
            
            guard let range: Range<String.Index> = Range(NSRange(contentRange, in: textContentStorage), in: base) else {
                return false
            }
            
            return b.body().range.overlaps(range)
        }
    }
}
