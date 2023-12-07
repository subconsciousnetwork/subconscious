//
//  BlockProtocols.swift
//  BlockEditor
//
//  Created by Gordon Brander on 8/7/23.
//

import Foundation

extension BlockEditor {
    enum BlockInlineFormattingAction: Hashable {
        case boldButtonPressed(id: UUID, text: String, selection: NSRange)
        case italicButtonPressed(id: UUID, text: String, selection: NSRange)
        case codeButtonPressed(id: UUID, text: String, selection: NSRange)
    }
    
    enum BlockTextEditingAction: Hashable {
        case requestSplit(
            id: UUID,
            selection: NSRange,
            text: String
        )
        case requestMergeUp(id: UUID)
        case didChange(
            id: UUID,
            dom: Subtext,
            selection: NSRange
        )
        case didChangeSelection(
            id: UUID,
            selection: NSRange
        )
        case didBeginEditing(id: UUID)
        case didEndEditing(id: UUID)
    }
    
    enum BlockControlsAction {
        case upButtonPressed(id: UUID)
        case downButtonPressed(id: UUID)
        case dismissKeyboardButtonPressed(id: UUID)
    }
    
    enum TextBlockAction {
        case inlineFormatting(BlockInlineFormattingAction)
        case textEditing(BlockTextEditingAction)
        case controls(BlockControlsAction)
        case onLink(URL)
        case transcludeList(TranscludeListAction)
    }
}

extension BlockEditor.TextBlockAction {
    static func from(
        id: UUID,
        action: SubtextTextEditorAction
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
        case let .textDidChange(dom, selection):
            return .textEditing(
                .didChange(id: id, dom: dom, selection: selection)
            )
        case .selectionDidChange(let selection):
            return .textEditing(
                .didChangeSelection(id: id, selection: selection)
            )
        case .didBeginEditing:
            return .textEditing(.didBeginEditing(id: id))
        case .didEndEditing:
            return .textEditing(.didEndEditing(id: id))
        case .onLink(let url):
            return .onLink(url)
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

extension BlockEditor.TextBlockAction {
    static func from(_ action: BlockEditor.TranscludeListAction) -> Self {
        .transcludeList(action)
    }
}
