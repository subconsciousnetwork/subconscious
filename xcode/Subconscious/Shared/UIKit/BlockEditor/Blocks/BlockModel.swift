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
        
        var isBlockSelected: Bool {
            switch self {
            case let .text(block):
                return block.isBlockSelected
            case let .heading(block):
                return block.isBlockSelected
            case let .quote(block):
                return block.isBlockSelected
            case let .list(block):
                return block.isBlockSelected
            }
        }

        var isBlockSelectedMode: Bool {
            switch self {
            case let .text(block):
                return block.isBlockSelectMode
            case let .heading(block):
                return block.isBlockSelectMode
            case let .quote(block):
                return block.isBlockSelectMode
            case let .list(block):
                return block.isBlockSelectMode
            }
        }

        /// Update inner text block model, returning a new self, of the same
        /// case as the original.
        /// In the case the block is not a text block, returns nil. There is
        /// currently no such block type, but in future there may be non-text
        /// block types, such as image.
        /// - Returns: self of same case, or nil
        func update(_ transform: (TextBlockModel) -> TextBlockModel) -> Self? {
            switch self {
            case .text(let block):
                return .text(transform(block))
            case .heading(let block):
                return .heading(transform(block))
            case .quote(let block):
                return .quote(transform(block))
            case .list(let block):
                return .list(transform(block))
            }
        }

        func setText(
            text: String,
            selection: NSRange
        ) -> Self? {
            update { block in
                block.setText(text: text, selection: selection)
            }
        }
        
        func setSelection(
            selection: NSRange
        ) -> Self? {
            update { block in
                block.setSelection(selection: selection)
            }
        }
        
        func setEditing(_ isEditing: Bool) -> Self? {
            update { block in
                var block = block
                block.isEditing = isEditing
                return block
            }
        }

        func setBlockSelectMode(
            _ isBlockSelectMode: Bool
        ) -> Self? {
            update { block in
                var block = block
                block.isBlockSelectMode = isBlockSelectMode
                return block
            }
        }
        
        func setBlockSelected(
            _ isBlockSelected: Bool
        ) -> Self? {
            update { block in
                var block = block
                block.isBlockSelected = isBlockSelected
                return block
            }
        }
    }
}
