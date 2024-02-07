//
//  BlockModel.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/28/23.
//

import Foundation

extension BlockEditor {
    enum BlockType: Hashable {
        case text
        case heading
        case quote
        case list
    }

    struct BlockModel: Hashable, Identifiable {
        var id = UUID()
        /// Block type-specific data
        var blockType: BlockType = .text
        var body = BlockBodyModel()
    }
}
