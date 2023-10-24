//
//  Tests_NotebookUpdate.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 8/30/22.
//

import XCTest
import ObservableStore
@testable import Subconscious

/// Tests for Notebook.update
class Tests_NotebookUpdate: XCTestCase {
    let environment = AppEnvironment()
    
    func testEntryCount() throws {
        let state = NotebookModel()
        let update = NotebookModel.update(
            state: state,
            action: .setEntryCount(10),
            environment: environment
        )
        XCTAssertEqual(
            update.state.entryCount,
            10,
            "Entry count correctly set"
        )
    }
    
    func testDeleteEntry() throws {
        let a = Slug(formatting: "A")!.toSlashlink()
        let b = Slug(formatting: "B")!.toLocalSlashlink()
        let c = Slug(formatting: "C")!.toLocalSlashlink()
        let state = NotebookModel(
            recent: [
                EntryStub(
                    did: Did.dummyData(),
                    address: a,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                ),
                EntryStub(
                    did: Did.dummyData(),
                    address: b,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                ),
                EntryStub(
                    did: Did.dummyData(),
                    address: c,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                )
            ]
        )
        let update = NotebookModel.update(
            state: state,
            action: .stageDeleteEntry(b),
            environment: environment
        )
        XCTAssertEqual(
            update.state.recent!.count,
            2,
            "Entry count correctly set"
        )
        XCTAssertEqual(
            update.state.recent![0].id,
            a,
            "Slug A is still first"
        )
        XCTAssertEqual(
            update.state.recent![1].id,
            c,
            "Slug C moved up because slug B was removed"
        )
    }
}
