//
//  Tests_MemoEditorDetailNotification.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 5/1/2024.
//

import XCTest
@testable import Subconscious

final class Tests_MemoEditorDetailNotification: XCTestCase {
    func testForwardRequestSaveEntry() throws {
        let memo = MemoEntry(address: Slashlink("/foo")!, contents: Memo.dummyData())
        let notification = MemoEditorDetailNotification.from(.forwardRequestSave(memo))!
        let action = DetailStackAction.tag(notification)
        XCTAssertEqual(action, .requestSaveEntry(memo))
    }
    
    func testForwardRequestDeleteEntry() throws {
        let notification = MemoEditorDetailNotification.from(.forwardRequestDelete(Slashlink("/foo")!))!
        let action = DetailStackAction.tag(notification)
        XCTAssertEqual(action, .requestDeleteEntry(Slashlink("/foo")!))
    }
    
    func testForwardRequestMoveEntry() throws {
        let notification = MemoEditorDetailNotification.from(.forwardRequestMoveEntry(from: Slashlink("/foo")!, to: Slashlink("/bar")!))!
        let action = DetailStackAction.tag(notification)
        XCTAssertEqual(action, .requestMoveEntry(from: Slashlink("/foo")!, to: Slashlink("/bar")!))
    }
    
    func testForwardRequestMergeEntry() throws {
        let notification = MemoEditorDetailNotification.from(.forwardRequestMergeEntry(parent: Slashlink("/foo")!, child: Slashlink("/bar")!))!
        let action = DetailStackAction.tag(notification)
        XCTAssertEqual(action, .requestMergeEntry(parent: Slashlink("/foo")!, child: Slashlink("/bar")!))
    }
    
    func testForwardRequestUpdateAudience() throws {
        let notification = MemoEditorDetailNotification.from(.forwardRequestUpdateAudience(address: Slashlink("/foo")!, .public))!
        let action = DetailStackAction.tag(notification)
        XCTAssertEqual(action, .requestUpdateAudience(Slashlink("/foo")!, .public))
    }
}
