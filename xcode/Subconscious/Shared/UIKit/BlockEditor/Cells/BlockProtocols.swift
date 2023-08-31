//
//  BlockProtocols.swift
//  BlockEditor
//
//  Created by Gordon Brander on 8/7/23.
//

import Foundation

protocol BlockInlineFormattingDelegate: AnyObject {
    func boldButtonPressed(id: UUID, text: String, selection: NSRange)
    func italicButtonPressed(id: UUID, text: String, selection: NSRange)
    func codeButtonPressed(id: UUID, text: String, selection: NSRange)
}

protocol BlockTextEditingDelegate: AnyObject {
    func requestSplit(
        id: UUID,
        selection: NSRange
    )
    func requestMerge(
        id: UUID
    )
    func didChange(
        id: UUID,
        text: String,
        selection: NSRange
    )
    func didChangeSelection(
        id: UUID,
        selection: NSRange
    )
    func didBeginEditing(id: UUID)
    func didEndEditing(id: UUID)
}

protocol BlockControlsDelegate: AnyObject {
    func upButtonPressed(id: UUID)
    func downButtonPressed(id: UUID)
    func dismissKeyboardButtonPressed(id: UUID)
}

protocol TextBlockDelegate:
    BlockInlineFormattingDelegate &
    BlockTextEditingDelegate &
    BlockControlsDelegate
{

}
