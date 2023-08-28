//
//  BlockModel.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/28/23.
//

import Foundation

extension BlockEditor {
    enum BlockModel: Hashable, Identifiable {
        case text(TextBlockModel)
        case heading(TextBlockModel)
        case quote(TextBlockModel)
        case list(TextBlockModel)
        
        var id: UUID {
            switch self {
            case .text(let block):
                return block.id
            case .heading(let block):
                return block.id
            case .quote(let block):
                return block.id
            case .list(let block):
                return block.id
            }
        }
        
        var text: String? {
            switch self {
            case .text(let block):
                return block.text
            case .heading(let block):
                return block.text
            case .quote(let block):
                return block.text
            case .list(let block):
                return block.text
            }
        }
        
        func setText(
            text: String,
            selection: NSRange
        ) -> Self? {
            switch self {
            case let .text(block):
                return .text(block.setText(text: text, selection: selection))
            case let .heading(block):
                return .heading(block.setText(text: text, selection: selection))
            case let .quote(block):
                return .quote(block.setText(text: text, selection: selection))
            case .list(let block):
                return .list(block.setText(text: text, selection: selection))
            }
        }
        
        func setSelection(
            selection: NSRange
        ) -> Self? {
            switch self {
            case let .text(block):
                return .text(block.setSelection(selection: selection))
            case let .heading(block):
                return .heading(block.setSelection(selection: selection))
            case let .quote(block):
                return .quote(block.setSelection(selection: selection))
            case .list(let block):
                return .list(block.setSelection(selection: selection))
            }
        }
        
        func setFocus(_ isFocused: Bool) -> Self {
            switch self {
            case let .text(block):
                var block = block
                block.isFocused = isFocused
                return .text(block)
            case let .heading(block):
                var block = block
                block.isFocused = isFocused
                return .heading(block)
            case let .quote(block):
                var block = block
                block.isFocused = isFocused
                return .quote(block)
            case let .list(block):
                var block = block
                block.isFocused = isFocused
                return .list(block)
            }
        }
    }
}
