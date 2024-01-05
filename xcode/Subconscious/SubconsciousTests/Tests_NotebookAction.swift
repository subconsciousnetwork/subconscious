//
//  Tests_NotebookAction.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/20/23.
//

import XCTest
@testable import Subconscious

final class Tests_NotebookAction: XCTestCase {
    func testFromSucceedMigrateDatabase() throws {
        let action = NotebookAction.from(.succeedMigrateDatabase(0))
        XCTAssertEqual(action, .ready)
    }
    
    func testFromSucceedSyncLocalFilesWithDatabase() throws {
        let action = NotebookAction.from(
            .succeedSyncLocalFilesWithDatabase([])
        )
        XCTAssertEqual(action, .ready)
    }
    
    func testFromSucceedIndexOurSphere() throws {
        let action = NotebookAction.from(
            .succeedIndexOurSphere(
                OurSphereRecord(
                    identity: Did("did:key:abc123")!,
                    since: "bafyfakefakefake"
                )
            )
        )
        XCTAssertEqual(action, .refreshLists)
    }
    
    func testFromSucceedRecoverOurSphere() throws {
        let action = NotebookAction.from(
            .succeedRecoverOurSphere
        )
        XCTAssertEqual(action, .refreshLists)
    }
    
    func testFromSucceedDeleteMemo() throws {
        let action = NotebookAction.from(
            .succeedDeleteMemo(Slashlink("/foo")!)
        )
        XCTAssertEqual(action, .succeedDeleteEntry(Slashlink("/foo")!))
    }
    
    func testFromFailDeleteMemo() throws {
        let action = NotebookAction.from(
            .failDeleteMemo("")
        )
        XCTAssertEqual(action, .failDeleteMemo(""))
    }
    
    func testFromRequestNotebookRoot() throws {
        let action = NotebookAction.from(
            .requestNotebookRoot
        )
        XCTAssertEqual(action, .requestNotebookRoot)
    }
}
