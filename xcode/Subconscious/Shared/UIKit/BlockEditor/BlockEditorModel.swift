//
//  BlockStackEditorModle.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/28/23.
//

import Foundation

extension BlockEditor {
    //  MARK: Model
    struct Model: Hashable {
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
    }
}
