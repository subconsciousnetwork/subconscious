//
//  BlocksModel.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 11/21/23.
//

import Foundation

extension BlockEditor {
    /// A list of blocks making up an editable document
    struct BlocksModel: Hashable, CustomStringConvertible {
        var description: String {
            // TODO: serialize to nice Subtext whitespace
            // https://github.com/subconsciousnetwork/subconscious/issues/1009
            blocks.map(\.body.dom.description).joined(separator: "\n\n")
        }
        private(set) var isBlockSelectMode = false
        var blocks: [BlockModel] = []

        mutating func enterBlockSelectMode(
            selecting: Set<UUID>
        ) {
            self.isBlockSelectMode = true
            self.blocks = blocks.map({ block in
                var block = block
                block.body.blockSelection.setBlockSelectMode(
                    isBlockSelectMode: true,
                    isBlockSelected: selecting.contains(block.id)
                )
                return block
            })
        }

        mutating func exitBlockSelectMode() {
            self.isBlockSelectMode = false
            self.blocks = blocks.map({ block in
                var block = block
                block.body.blockSelection.setBlockSelectMode(
                    isBlockSelectMode: false,
                    isBlockSelected: false
                )
                return block
            })
        }

    }
}

extension BlockEditor.BlocksModel: LosslessStringConvertible {
    init(_ description: String) {
        let subtext = Subtext(markup: description)
        let blocks: [BlockEditor.BlockModel] = subtext.blocks
            .compactMap({ block in
                switch block {
                case .empty:
                    // TODO: Do something smarter with whitespace
                    // https://github.com/subconsciousnetwork/subconscious/issues/1009
                    return nil
                case let .text(span, _):
                    return BlockEditor.BlockModel(
                        blockType: .text,
                        body: BlockEditor.BlockBodyModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                case let .heading(span):
                    return BlockEditor.BlockModel(
                        blockType: .heading,
                        body: BlockEditor.BlockBodyModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                case let .list(span, _):
                    return BlockEditor.BlockModel(
                        blockType: .list,
                        body: BlockEditor.BlockBodyModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                case let .quote(span, _):
                    return BlockEditor.BlockModel(
                        blockType: .quote,
                        body: BlockEditor.BlockBodyModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                }
            })
        self.blocks = blocks
    }
}
