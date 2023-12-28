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
            blocks.compactMap(\.dom?.description).joined(separator: "\n\n")
        }
        var isBlockSelectMode = false
        var blocks: [BlockModel] = []

        func setBlockSelectMode(
            isSelected: Bool,
            selecting: Set<UUID>
        ) -> Self {
            var this = self
            this.isBlockSelectMode = true
            this.blocks = blocks.map({ block in
                block.setBlockSelectMode(
                    isBlockSelectMode: true,
                    isBlockSelected: selecting.contains(block.id)
                )
            })
            return this
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
                    return .text(
                        BlockEditor.TextBlockModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                case let .heading(span):
                    return .heading(
                        BlockEditor.TextBlockModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                case let .list(span, _):
                    return .list(
                        BlockEditor.TextBlockModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                case let .quote(span, _):
                    return .quote(
                        BlockEditor.TextBlockModel(
                            dom: Subtext(markup: span.description)
                        )
                    )
                }
            })
        self.blocks = blocks
    }
}
