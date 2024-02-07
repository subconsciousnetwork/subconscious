//
//  Tests_NotebookDetailStackCursor.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/20/23.
//

import XCTest
@testable import Subconscious

final class Tests_NotebookDetailStackCursor: XCTestCase {
    func testTagRequestSaveEntry() throws {
        let memo = MemoEntry(address: Slashlink("@bob/foo")!, contents: Memo.dummyData())
        let action = NotebookDetailStackCursor.tag(
            .requestSaveEntry(memo)
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestSaveEntry(memo)
        )
    }
    
    func testTagRequestDeleteEntry() throws {
        let action = NotebookDetailStackCursor.tag(
            .requestDeleteEntry(Slashlink("@bob/foo")!)
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestDeleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testTagRequestMoveEntry() throws {
        let action = NotebookDetailStackCursor.tag(
            .requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testTagRequestMergeEntry() throws {
        let action = NotebookDetailStackCursor.tag(
            .requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
    }
    
    func testTagRequestUpdateAudience() throws {
        let action = NotebookDetailStackCursor.tag(
            .requestUpdateAudience(Slashlink("@bob/foo")!, .public)
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestUpdateAudience(Slashlink("@bob/foo")!, .public)
        )
    }
    
    func testTagRequestAssignNoteColor() throws {
        let action = NotebookDetailStackCursor.tag(
            .requestAssignNoteColor(Slashlink("@bob/foo")!, .c)
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestAssignNoteColor(Slashlink("@bob/foo")!, .c)
        )
    }
    
    func testTagRequestAppendToEntry() throws {
        let action = NotebookDetailStackCursor.tag(
            .requestAppendToEntry(Slashlink("@bob/foo")!, "test")
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestAppendToEntry(Slashlink("@bob/foo")!, "test")
        )
    }
}
