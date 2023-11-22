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
            text: String,
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
    }
}
