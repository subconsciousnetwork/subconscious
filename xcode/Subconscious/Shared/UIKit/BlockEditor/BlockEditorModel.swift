//
//  BlockStackEditorModle.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/28/23.
//
import Foundation
import ObservableStore
import os

extension BlockEditor {
    // MARK: Model
    struct Model: Hashable {
        static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditor.Model"
        )

        /// Create a BlockEditor "draft" document.
        /// A draft is a document with a heading block and nothing else.
        static func draft() -> Self {
            Model(
                blocks: [
                    BlockModel.heading(TextBlockModel())
                ]
            )
        }

        var isBlockSelectMode = false
        var blocks: [BlockModel] = []
        var appendix = RelatedModel()

        func block(id: UUID) -> Array.Index? {
            guard let i = blocks.firstIndex(whereID: id) else {
                Self.logger.log("block#\(id) not found.")
                return nil
            }
            return i
        }
    }
}

extension BlockEditor.Model: ModelProtocol {
    static func update(
        state: BlockEditor.Model,
        action: BlockEditor.Action,
        environment: AppEnvironment
    ) -> ObservableStore.Update<BlockEditor.Model> {
        return Update(state: state)
    }
}
