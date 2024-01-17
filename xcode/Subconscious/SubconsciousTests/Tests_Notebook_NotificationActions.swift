//
//  Test_Notebook_NotificationActions.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 5/1/2024.
//

import XCTest
@testable import Subconscious

final class Tests_Notebook_NotificationActions: XCTestCase {
    func testRequestSaveEntry() throws {
        let memo = MemoEntry(address: Slashlink("@bob/foo")!, contents: Memo.dummyData())
        let action = AppAction.from(NotebookAction.requestSaveEntry(memo))
        XCTAssertEqual(
            action,
            AppAction.saveEntry(memo)
        )
    }
    
    func testRequestDeleteEntry() throws {
        let action = AppAction.from(NotebookAction.requestDeleteEntry(Slashlink("@bob/foo")!))
        XCTAssertEqual(
            action,
            AppAction.deleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testRequestMoveEntry() throws {
        let action = AppAction.from(NotebookAction.requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            AppAction.moveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testRequestMergeEntry() throws {
        let action = AppAction.from(NotebookAction.requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            AppAction.mergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
    }
    
    func testRequestUpdateAudiece() throws {
        let action = AppAction.from(NotebookAction.requestUpdateAudience(Slashlink("@bob/foo")!, .public))
        XCTAssertEqual(
            action,
            AppAction.updateAudience(address: Slashlink("@bob/foo")!, audience: .public)
        )
    }
    
    func testRequestAssignNoteColor() throws {
        let action = AppAction.from(NotebookAction.requestAssignNoteColor(Slashlink("@bob/foo")!, .a))
        XCTAssertEqual(
            action,
            AppAction.assignColor(address: Slashlink("@bob/foo")!, color: .a)
        )
    }
    
    func testSucceedSaveEntry() throws {
        let time = Date.now
        let action = NotebookAction.from(.succeedSaveEntry(address: Slashlink("@bob/foo")!, modified: time))
        XCTAssertEqual(
            action,
            NotebookAction.succeedSaveEntry(Slashlink("@bob/foo")!, time)
        )
    }
    
    func testSucceedDeleteEntry() throws {
        let action = NotebookAction.from(.succeedDeleteEntry(Slashlink("@bob/foo")!))
        XCTAssertEqual(
            action,
            NotebookAction.succeedDeleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testSucceedMoveEntry() throws {
        let action = NotebookAction.from(.succeedMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            NotebookAction.succeedMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testSucceedMergeEntry() throws {
        let action = NotebookAction.from(.succeedMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            NotebookAction.succeedMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
    }
    
    func testSucceedUpdateAudience() throws {
        let receipt = MoveReceipt(
            from: Slashlink(
                "@bob/foo"
            )!,
            to: Slashlink(
                "@bob/bar"
            )!
        )
        let action = NotebookAction.from(
            .succeedUpdateAudience(
                receipt
            )
        )
        XCTAssertEqual(
            action,
            NotebookAction.succeedUpdateAudience(receipt)
        )
    }
    
    func testSucceedAssignNoteColor() throws {
        let action = NotebookAction.from(
            .succeedAssignNoteColor(
                address: Slashlink("@bob/foo")!,
                color: .a
            )
        )
        XCTAssertEqual(
            action,
            NotebookAction.succeedAssignNoteColor(
                Slashlink("@bob/foo")!,
                .a
            )
        )
    }
}

