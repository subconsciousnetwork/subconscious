//
//  Test_HomeProfile_NotificationActions.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 5/1/2024.
//

import XCTest
@testable import Subconscious

final class Tests_HomeProfile_NotificationActions: XCTestCase {
    func testRequestSaveEntry() throws {
        let memo = MemoEntry(address: Slashlink("@bob/foo")!, contents: Memo.dummyData())
        let action = AppAction.from(HomeProfileAction.requestSaveEntry(memo))
        XCTAssertEqual(
            action,
            AppAction.saveEntry(memo)
        )
    }
    
    func testRequestDeleteEntry() throws {
        let action = AppAction.from(HomeProfileAction.requestDeleteEntry(Slashlink("@bob/foo")!))
        XCTAssertEqual(
            action,
            AppAction.deleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testRequestMoveEntry() throws {
        let action = AppAction.from(HomeProfileAction.requestMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            AppAction.moveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testRequestMergeEntry() throws {
        let action = AppAction.from(HomeProfileAction.requestMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            AppAction.mergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
        )
    }
    
    func testRequestUpdateAudiece() throws {
        let action = AppAction.from(HomeProfileAction.requestUpdateAudience(Slashlink("@bob/foo")!, .public))
        XCTAssertEqual(
            action,
            AppAction.updateAudience(address: Slashlink("@bob/foo")!, audience: .public)
        )
    }
    
    func testRequestAssignNoteColor() throws {
        let action = AppAction.from(HomeProfileAction.requestAssignNoteColor(Slashlink("@bob/foo")!, .tan))
        XCTAssertEqual(
            action,
            AppAction.assignColor(address: Slashlink("@bob/foo")!, color: .tan)
        )
    }
    
    func testSucceedSaveEntry() throws {
        let time = Date.now
        let action = HomeProfileAction.from(.succeedSaveEntry(address: Slashlink("@bob/foo")!, modified: time))
        XCTAssertEqual(
            action,
            HomeProfileAction.succeedSaveEntry(Slashlink("@bob/foo")!, time)
        )
    }
    
    func testSucceedDeleteEntry() throws {
        let action = HomeProfileAction.from(.succeedDeleteEntry(Slashlink("@bob/foo")!))
        XCTAssertEqual(
            action,
            HomeProfileAction.succeedDeleteEntry(Slashlink("@bob/foo")!)
        )
    }
    
    func testSucceedMoveEntry() throws {
        let action = HomeProfileAction.from(.succeedMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            HomeProfileAction.succeedMoveEntry(from: Slashlink("@bob/foo")!, to: Slashlink("@bob/bar")!)
        )
    }
    
    func testSucceedMergeEntry() throws {
        let action = HomeProfileAction.from(.succeedMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!))
        XCTAssertEqual(
            action,
            HomeProfileAction.succeedMergeEntry(parent: Slashlink("@bob/foo")!, child: Slashlink("@bob/bar")!)
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
        let action = HomeProfileAction.from(
            .succeedUpdateAudience(
                receipt
            )
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.succeedUpdateAudience(receipt)
        )
    }
    
    func testSucceedAssignNoteColor() throws {
        let action = HomeProfileAction.from(
            .succeedAssignNoteColor(
                address: Slashlink("@bob/foo")!,
                color: .tan
            )
        )
        XCTAssertEqual(
            action,
            HomeProfileAction.succeedAssignNoteColor(
                Slashlink("@bob/foo")!,
                .tan
            )
        )
    }
}

