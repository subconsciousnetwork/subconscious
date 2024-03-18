//
//  SubtextTextEditorView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 11/22/23.
//

import UIKit

enum SubtextTextEditorAction: Hashable {
    case requestSplit(text: String, selection: NSRange)
    case requestMergeUp
    case textDidChange(dom: Subtext, selection: NSRange)
    case selectionDidChange(selection: NSRange)
    case didBeginEditing
    case didEndEditing
    
    /// Link tap in linked text
    case activateLink(URL)

    case upButtonPressed
    case downButtonPressed
    case boldButtonPressed(text: String, selection: NSRange)
    case italicButtonPressed(text: String, selection: NSRange)
    case codeButtonPressed(text: String, selection: NSRange)
    case dismissKeyboardButtonPressed
}

/// Extends SubtextTextView, offering:
/// - A a configured keyboard toolbar
/// - Callbacks for significant events
class SubtextTextEditorView: UIView.SubtextTextView {
    private lazy var toolbar = UIToolbar.blockToolbar(
        send: { [weak self] action in
            self?.send(action)
        }
    )
    
    var send: (SubtextTextEditorAction) -> Void
    
    init(
        frame: CGRect = .zero,
        textContainer: NSTextContainer? = nil,
        send: @escaping (SubtextTextEditorAction) -> Void
    ) {
        self.send = send
        super.init(frame: frame, textContainer: textContainer)
        self.delegate = self
        self.inputAccessoryView = toolbar
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func send(
        _ action: BlockEditor.BlockToolbarAction
    ) {
        self.send(self.tag(action))
    }

    private func tag(
        _ action: BlockEditor.BlockToolbarAction
    ) -> SubtextTextEditorAction {
        switch action {
        case .upButtonPressed:
            return .upButtonPressed
        case .downButtonPressed:
            return .downButtonPressed
        case .dismissKeyboardButtonPressed:
            return .dismissKeyboardButtonPressed
        case .boldButtonPressed:
            return .boldButtonPressed(text: text, selection: selectedRange)
        case .italicButtonPressed:
            return .italicButtonPressed(text: text, selection: selectedRange)
        case .codeButtonPressed:
            return .codeButtonPressed(text: text, selection: selectedRange)
        }
    }
}

extension SubtextTextEditorView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        // Enter/newline
        if text.contains("\n") {
            self.send(
                .requestSplit(
                    text: text,
                    selection: self.selectedRange
                )
            )
            return false
        }
        // Hit delete while cursor was at beginning of block
        else if range.length == 0 && text.isEmpty {
            self.send(.requestMergeUp)
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        UIView.performWithoutAnimation {
            self.invalidateIntrinsicContentSize()
        }
        self.send(
            .textDidChange(dom: dom, selection: selectedRange)
        )
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        self.send(
            .selectionDidChange(
                selection: self.selectedRange
            )
        )
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.send(.didBeginEditing)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.send(.didEndEditing)
    }

    /// Handle link taps
    func textView(
        _ textView: UITextView,
        primaryActionFor textItem: UITextItem,
        defaultAction: UIAction
    ) -> UIAction? {
        if case .link(let url) = textItem.content {
            self.send(.activateLink(url))
            return .none
        }
        return defaultAction
    }
}
