//
//  Tests_BlockEditorBlockModel.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/31/23.
//

import XCTest
@testable import Subconscious

final class Tests_BlockEditorBlockModel: XCTestCase {
    func testUpdate() throws {
        let modelA = BlockEditor.TextBlockModel()
        var modelB = modelA
        modelB.isEditing = true

        let textBlock = BlockEditor.BlockModel.text(modelA)
        let textBlockUpdate = textBlock.update { block in
            var block = block
            block.isEditing = true
            return block
        }
        XCTAssertEqual(textBlockUpdate, .text(modelB))

        let headingBlock = BlockEditor.BlockModel.heading(modelA)
        let headingBlockUpdate = headingBlock.update { block in
            var block = block
            block.isEditing = true
            return block
        }
        XCTAssertEqual(headingBlockUpdate, .heading(modelB))

        let quoteBlock = BlockEditor.BlockModel.quote(modelA)
        let quoteBlockUpdate = quoteBlock.update { block in
            var block = block
            block.isEditing = true
            return block
        }
        XCTAssertEqual(quoteBlockUpdate, .quote(modelB))

        let listBlock = BlockEditor.BlockModel.list(modelA)
        let listBlockUpdate = listBlock.update { block in
            var block = block
            block.isEditing = true
            return block
        }
        XCTAssertEqual(listBlockUpdate, .list(modelB))
    }
}
