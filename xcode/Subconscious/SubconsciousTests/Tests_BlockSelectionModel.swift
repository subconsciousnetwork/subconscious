//
//  Tests_BlockSelectionModel.swift
//  Tests iOS
//
//  Created by Gordon Brander on 2/7/24.
//

import XCTest
@testable import Subconscious

final class Tests_BlockSelectionModel: XCTestCase {
    func testBlockSelected() throws {
        var selection = BlockEditor.BlockSelectionModel()
        selection.setBlockSelectMode(
            isBlockSelectMode: true,
            isBlockSelected: true
        )
        XCTAssert(selection.isBlockSelectMode)
        XCTAssert(selection.isBlockSelected)
    }

    func testBlockSelectedNotInSelectMode() throws {
        var selection = BlockEditor.BlockSelectionModel()
        selection.setBlockSelectMode(
            isBlockSelectMode: false,
            isBlockSelected: true
        )
        XCTAssert(!selection.isBlockSelectMode)
        XCTAssert(!selection.isBlockSelected)
    }

    func testBlockNotSelectedSelectMode() throws {
        var selection = BlockEditor.BlockSelectionModel()
        selection.setBlockSelectMode(
            isBlockSelectMode: true,
            isBlockSelected: true
        )
        selection.setBlockSelected(false)
        XCTAssert(selection.isBlockSelectMode)
        XCTAssert(!selection.isBlockSelected)
    }
}
