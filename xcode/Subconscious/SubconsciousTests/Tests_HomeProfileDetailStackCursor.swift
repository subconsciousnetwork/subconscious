//
//  Tests_HomeProfileDetailStackCursor.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 5/1/2024.
//

import XCTest
@testable import Subconscious

final class Tests_HomeProfileDetailStackCursor: XCTestCase {
    func testTagRequestSaveEntry() throws {
        let memo = MemoEntry(address: Slashlink("@bob/foo")!, contents: Memo.dummyData())
        let action = HomeProfileDetailStackCursor.tag(
            .requestSaveEntry(memo)
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.requestSaveEntry(memo)
        )
    }
    
    func testTagRequestDeleteEntry() throws {
        let action = HomeProfileDetailStackCursor.tag(
            .requestDeleteEntry(Slashlink("@bob/foo")!)
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.requestDeleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testTagRequestMoveEntry() throws {
        let action = HomeProfileDetailStackCursor.tag(
            .requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testTagRequestMergeEntry() throws {
        let action = HomeProfileDetailStackCursor.tag(
            .requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
    }
    
    func testTagRequestUpdateAudience() throws {
        let action = HomeProfileDetailStackCursor.tag(
            .requestUpdateAudience(Slashlink("@bob/foo")!, .public)
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.requestUpdateAudience(Slashlink("@bob/foo")!, .public)
        )
    }
    
    func testTagRequestAssignNoteColor() throws {
        let action = HomeProfileDetailStackCursor.tag(
            .requestAssignNoteColor(Slashlink("@bob/foo")!, .e)
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.requestAssignNoteColor(Slashlink("@bob/foo")!, .e)
        )
    }
    
    func testTagRequestAppendToEntry() throws {
        let action = HomeProfileDetailStackCursor.tag(
            .requestAppendToEntry(Slashlink("@bob/foo")!, "test")
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.requestAppendToEntry(Slashlink("@bob/foo")!, "test")
        )
    }
}

