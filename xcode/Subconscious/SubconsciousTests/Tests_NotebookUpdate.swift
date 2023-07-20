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
                    address: a,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now,
                    author: nil
                ),
                EntryStub(
                    address: b,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now,
                    author: nil
                ),
                EntryStub(
                    address: c,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now,
                    author: nil
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
    
    func testViewerSlashlinkConstruction() throws {
        let model = NotebookModel()
        
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        
        let action = MemoViewerDetailNotification.requestFindLinkDetail(
            address: Slashlink(petname: Petname("origin")!),
            link: link
        )
        
        let newAction = NotebookAction.tag(action)
        let update = NotebookModel.update(
            state: model,
            action: newAction,
            environment: environment
        )
        
        if let detail = update.state.details.first?.address,
           let petname = detail.petname {
            XCTAssertEqual(petname, Petname("bob.alice.origin")!)
            XCTAssertEqual(detail.slug, Slug("hello")!)
        } else {
            XCTFail("No detail")
            return
        }
    }
    
    func testEditorSlashlinkConstruction() throws {
        let model = NotebookModel()
        
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        
        let action = MemoEditorDetailNotification.requestFindLinkDetail(
            link: link
        )
        
        let newAction = NotebookAction.tag(action)
        let update = NotebookModel.update(
            state: model,
            action: newAction,
            environment: environment
        )
        
        if let detail = update.state.details.first?.address,
           let petname = detail.petname {
            XCTAssertEqual(petname, Petname("bob.alice")!)
            XCTAssertEqual(detail.slug, Slug("hello")!)
        } else {
            XCTFail("No detail")
            return
        }
    }
}
