//
//  Tests_DeckDetailStackCursor.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 5/1/2024.
//

import XCTest
@testable import Subconscious

final class Tests_DeckDetailStackCursor: XCTestCase {
    func testTagRequestSaveEntry() throws {
        let memo = MemoEntry(address: Slashlink("@bob/foo")!, contents: Memo.dummyData())
        let action = DeckDetailStackCursor.tag(
            .requestSaveEntry(memo)
        )
        XCTAssertEqual(
            action,
            DeckAction.requestSaveEntry(memo)
        )
    }
    
    func testTagRequestDeleteEntry() throws {
        let action = DeckDetailStackCursor.tag(
            .requestDeleteEntry(Slashlink("@bob/foo")!)
        )
        XCTAssertEqual(
            action,
            DeckAction.requestDeleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testTagRequestMoveEntry() throws {
        let action = DeckDetailStackCursor.tag(
            .requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
        XCTAssertEqual(
            action,
            DeckAction.requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testTagRequestMergeEntry() throws {
        let action = DeckDetailStackCursor.tag(
            .requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
        XCTAssertEqual(
            action,
            DeckAction.requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
    }
    
    func testTagRequestUpdateAudience() throws {
        let action = DeckDetailStackCursor.tag(
            .requestUpdateAudience(Slashlink("@bob/foo")!, .public)
        )
        XCTAssertEqual(
            action,
            DeckAction.requestUpdateAudience(Slashlink("@bob/foo")!, .public)
        )
    }
    
    func testTagRequestAssignNoteColor() throws {
        let action = DeckDetailStackCursor.tag(
            .requestAssignNoteColor(Slashlink("@bob/foo")!, .b)
        )
        XCTAssertEqual(
            action,
            DeckAction.requestAssignNoteColor(Slashlink("@bob/foo")!, .b)
        )
    }
}

