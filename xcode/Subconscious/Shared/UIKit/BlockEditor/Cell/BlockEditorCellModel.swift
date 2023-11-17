//
//  BlockEditorCellModel.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 11/17/23.
//

import Foundation

extension BlockEditor {
    struct CellModel: Hashable, Identifiable {
        var id = UUID()
        var content: CellContentModel
    }

    enum CellContentModel: Hashable {
        case blocks(BlockModel)
        case appendix(RelatedModel)
    }
}
