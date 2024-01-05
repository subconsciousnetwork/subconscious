//
//  Tests_NotebookDetailStackCursor.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/20/23.
//

import XCTest
@testable import Subconscious

final class Tests_NotebookDetailStackCursor: XCTestCase {
    func testTagRequestDeleteMemo() throws {
        let action = NotebookDetailStackCursor.tag(
            .requestDeleteEntry(Slashlink("@bob/foo")!)
        )
        XCTAssertEqual(
            action,
            NotebookAction.requestDeleteMemo(Slashlink("@bob/foo")!)
        )
    }
    
    func testTagSucceedMergeEntry() throws {
        let action = NotebookDetailStackCursor.tag(
            .succeedMergeEntry(
                parent: Slashlink("/foo")!,
                child: Slashlink("/bar")!
            )
        )
        XCTAssertEqual(
            action,
            NotebookAction.succeedMergeEntry(
                parent: Slashlink("/foo")!,
                child: Slashlink("/bar")!
            )
        )
    }
    
    func testTagSucceedMoveEntry() throws {
        let action = NotebookDetailStackCursor.tag(
            .succeedMoveEntry(
                from: Slashlink("/foo")!,
                to: Slashlink("/bar")!
            )
        )
        XCTAssertEqual(
            action,
            NotebookAction.succeedMoveEntry(
                from: Slashlink("/foo")!,
                to: Slashlink("/bar")!
            )
        )
    }
    
    func testTagSucceedUpdateAudience() throws {
        let action = NotebookDetailStackCursor.tag(
            .succeedUpdateAudience(
                MoveReceipt(
                    from: Slashlink("/foo")!,
                    to: Slashlink("/bar")!
                )
            )
        )
        XCTAssertEqual(
            action,
            NotebookAction.succeedUpdateAudience(
                MoveReceipt(
                    from: Slashlink("/foo")!,
                    to: Slashlink("/bar")!
                )
            )
        )
    }
    
    func testTagSucceedSaveEntry() throws {
        let date = Date.now
        let action = NotebookDetailStackCursor.tag(
            .succeedSaveEntry(
                address: Slashlink("/bar")!,
                modified: date
            )
        )
        XCTAssertEqual(
            action,
            NotebookAction.succeedSaveEntry(
                slug: Slashlink("/bar")!,
                modified: date
            )
        )
    }
}
