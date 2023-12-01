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
            blocks.compactMap(\.text).joined(separator: "\n\n")
        }
        var isBlockSelectMode = false
        var blocks: [BlockModel] = []
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
                            text: span.description
                        )
                    )
                case let .heading(span):
                    return .heading(
                        BlockEditor.TextBlockModel(
                            text: span.description
                        )
                    )
                case let .list(span, _):
                    return .list(
                        BlockEditor.TextBlockModel(
                            text: span.description
                        )
                    )
                case let .quote(span, _):
                    return .quote(
                        BlockEditor.TextBlockModel(
                            text: span.description
                        )
                    )
                }
            })
        self.blocks = blocks
    }
}
