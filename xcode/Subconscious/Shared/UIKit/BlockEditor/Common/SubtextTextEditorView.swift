//
//  SubtextTextEditorView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 11/22/23.
//

import UIKit

extension UIView {
    /// Extends SubtextTextView, offering:
    /// - A a configured keyboard toolbar
    /// - Callbacks for significant events
    class SubtextTextEditorView: UIView.SubtextTextView {
        enum Action {
            case requestSplit(text: String, selection: NSRange)
            case requestMergeUp
            case textDidChange(text: String, selection: NSRange)
            case selectionDidChange(selection: NSRange)
            case didBeginEditing
            case didEndEditing
            
            case upButtonPressed
            case downButtonPressed
            case boldButtonPressed(text: String, selection: NSRange)
            case italicButtonPressed(text: String, selection: NSRange)
            case codeButtonPressed(text: String, selection: NSRange)
            case dismissKeyboardButtonPressed
        }

        private lazy var toolbar = UIToolbar.blockToolbar(
            upButtonPressed: { [weak self] in
                self?.send(.upButtonPressed)
            },
            downButtonPressed: { [weak self] in
                self?.send(.downButtonPressed)
            },
            boldButtonPressed: { [weak self] in
                if let self = self {
                    self.send(
                        .boldButtonPressed(
                            text: self.text,
                            selection: self.selectedRange
                        )
                    )
                }
            },
            italicButtonPressed: { [weak self] in
                if let self = self {
                    self.send(
                        .italicButtonPressed(
                            text: self.text,
                            selection: self.selectedRange
                        )
                    )
                }
            },
            codeButtonPressed: { [weak self] in
                if let self = self {
                    self.send(
                        .codeButtonPressed(
                            text: self.text,
                            selection: self.selectedRange
                        )
                    )
                }            },
            dismissKeyboardButtonPressed: { [weak self] in
                self?.send(.dismissKeyboardButtonPressed)
            }
        )
        
        var send: (Action) -> Void
        
        init(
            frame: CGRect = .zero,
            textContainer: NSTextContainer? = nil,
            send: @escaping (Action) -> Void
        ) {
            self.send = send
            super.init(frame: frame, textContainer: textContainer)
            self.delegate = self
            self.inputAccessoryView = toolbar
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension BlockEditor.TextBlockAction {
    static func from(
        id: UUID,
        action: UIView.SubtextTextEditorView.Action
    ) -> Self {
        switch action {
        case .requestSplit(let text, let selection):
            return .textEditing(
                .requestSplit(id: id, selection: selection, text: text)
            )
        case .requestMergeUp:
            return .textEditing(
                .requestMergeUp(id: id)
            )
        case .textDidChange(let text, let selection):
            return .textEditing(
                .didChange(id: id, text: text, selection: selection)
            )
        case .selectionDidChange(let selection):
            return .textEditing(
                .didChangeSelection(id: id, selection: selection)
            )
        case .didBeginEditing:
            return .textEditing(.didBeginEditing(id: id))
        case .didEndEditing:
            return .textEditing(.didEndEditing(id: id))
        case .upButtonPressed:
            return .controls(.upButtonPressed(id: id))
        case .downButtonPressed:
            return .controls(.downButtonPressed(id: id))
        case .dismissKeyboardButtonPressed:
            return .controls(.dismissKeyboardButtonPressed(id: id))
        case .boldButtonPressed(let text, let selection):
            return .inlineFormatting(
                .boldButtonPressed(
                    id: id,
                    text: text,
                    selection: selection
                )
            )
        case .italicButtonPressed(let text, let selection):
            return .inlineFormatting(
                .italicButtonPressed(
                    id: id,
                    text: text,
                    selection: selection
                )
            )
        case .codeButtonPressed(let text, let selection):
            return .inlineFormatting(
                .codeButtonPressed(
                    id: id,
                    text: text,
                    selection: selection
                )
            )
        }
    }
}

extension UIView.SubtextTextEditorView: UITextViewDelegate {
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
            .textDidChange(text: text, selection: selectedRange)
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
}
