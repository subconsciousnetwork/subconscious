//
//  Tests_Deck_NotificationActions.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 5/1/2024.
//

import XCTest
@testable import Subconscious

final class Tests_Deck_NotificationActions: XCTestCase {
    func testRequestSaveEntry() throws {
        let memo = MemoEntry(address: Slashlink("@bob/foo")!, contents: Memo.dummyData())
        let action = AppAction.from(DeckAction.requestSaveEntry(memo))
        XCTAssertEqual(
            action,
            AppAction.saveEntry(memo)
        )
    }
    
    func testRequestDeleteEntry() throws {
        let action = AppAction.from(DeckAction.requestDeleteEntry(Slashlink("@bob/foo")!))
        XCTAssertEqual(
            action,
            AppAction.deleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testRequestMoveEntry() throws {
        let action = AppAction.from(DeckAction.requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            AppAction.moveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testRequestMergeEntry() throws {
        let action = AppAction.from(DeckAction.requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            AppAction.mergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
    }
    
    func testRequestUpdateAudiece() throws {
        let action = AppAction.from(DeckAction.requestUpdateAudience(Slashlink("@bob/foo")!, .public))
        XCTAssertEqual(
            action,
            AppAction.updateAudience(address: Slashlink("@bob/foo")!, audience: .public)
        )
    }
    
    func testRequestAssignNoteColor() throws {
        let action = AppAction.from(DeckAction.requestAssignNoteColor(Slashlink("@bob/foo")!, .d))
        XCTAssertEqual(
            action,
            AppAction.assignColor(address: Slashlink("@bob/foo")!, color: .d)
        )
    }
    
    func testSucceedSaveEntry() throws {
        let time = Date.now
        let action = DeckAction.from(.succeedSaveEntry(address: Slashlink("@bob/foo")!, modified: time))
        XCTAssertEqual(
            action,
            DeckAction.succeedSaveEntry(Slashlink("@bob/foo")!, time)
        )
    }
    
    func testSucceedDeleteEntry() throws {
        let action = DeckAction.from(.succeedDeleteEntry(Slashlink("@bob/foo")!))
        XCTAssertEqual(
            action,
            DeckAction.succeedDeleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testSucceedMoveEntry() throws {
        let action = DeckAction.from(.succeedMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            DeckAction.succeedMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testSucceedMergeEntry() throws {
        let action = DeckAction.from(.succeedMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            DeckAction.succeedMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
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
        let action = DeckAction.from(
            .succeedUpdateAudience(
                receipt
            )
        )
        XCTAssertEqual(
            action,
            DeckAction.succeedUpdateAudience(receipt)
        )
    }
    
    func testSucceedAssignNoteColor() throws {
        let action = DeckAction.from(
            .succeedAssignNoteColor(
                address: Slashlink("@bob/foo")!,
                color: .d
            )
        )
        XCTAssertEqual(
            action,
            DeckAction.succeedAssignNoteColor(
                Slashlink("@bob/foo")!,
                .d
            )
        )
    }
}

