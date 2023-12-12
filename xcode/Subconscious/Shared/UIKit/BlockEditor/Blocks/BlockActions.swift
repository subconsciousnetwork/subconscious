//
//  BlockProtocols.swift
//  BlockEditor
//
//  Created by Gordon Brander on 8/7/23.
//

import Foundation

extension BlockEditor {
    enum TextBlockAction {
        case boldButtonPressed(id: UUID, text: String, selection: NSRange)
        case italicButtonPressed(id: UUID, text: String, selection: NSRange)
        case codeButtonPressed(id: UUID, text: String, selection: NSRange)
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
        case upButtonPressed(id: UUID)
        case downButtonPressed(id: UUID)
        case dismissKeyboardButtonPressed(id: UUID)
        case activateLink(URL)
        case requestTransclude(EntryStub)
        case requestLink(Peer, SubSlashlinkLink)
    }
}

extension BlockEditor.TextBlockAction {
    static func from(
        id: UUID,
        action: SubtextTextEditorAction
    ) -> Self {
        switch action {
        case .requestSplit(let text, let selection):
            return .requestSplit(id: id, selection: selection, text: text)
        case .requestMergeUp:
            return .requestMergeUp(id: id)
        case let .textDidChange(dom, selection):
            return .didChange(id: id, dom: dom, selection: selection)
        case .selectionDidChange(let selection):
            return .didChangeSelection(id: id, selection: selection)
        case .didBeginEditing:
            return .didBeginEditing(id: id)
        case .didEndEditing:
            return .didEndEditing(id: id)
        case .activateLink(let url):
            return .activateLink(url)
        case .upButtonPressed:
            return .upButtonPressed(id: id)
        case .downButtonPressed:
            return .downButtonPressed(id: id)
        case .dismissKeyboardButtonPressed:
            return .dismissKeyboardButtonPressed(id: id)
        case .boldButtonPressed(let text, let selection):
            return .boldButtonPressed(
                id: id,
                text: text,
                selection: selection
            )
        case .italicButtonPressed(let text, let selection):
            return .italicButtonPressed(
                id: id,
                text: text,
                selection: selection
            )
        case .codeButtonPressed(let text, let selection):
            return .codeButtonPressed(
                id: id,
                text: text,
                selection: selection
            )
        }
    }
}

extension BlockEditor.TextBlockAction {
    static func from(_ action: BlockEditor.TranscludeListAction) -> Self {
        switch action {
        case .requestTransclude(let entryStub):
            return .requestTransclude(entryStub)
        case .requestLink(let peer, let subSlashlinkLink):
            return .requestLink(peer, subSlashlinkLink)
        }
    }
}
