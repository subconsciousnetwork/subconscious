//
//  Tests_DetailStack.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 6/9/2023.
//

import XCTest
import ObservableStore
@testable import Subconscious

class Tests_DetailStack: XCTestCase {
    let environment = AppEnvironment()

    func testViewerSlashlinkConstruction() throws {
        let model = DetailStackModel()
        
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        
        let action = MemoViewerDetailNotification.requestFindLinkDetail(
            address: Slashlink(petname: Petname("origin")!),
            link: link
        )
        
        let newAction = DetailStackAction.tag(action)
        let update = DetailStackModel.update(
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
        let model = DetailStackModel()
        
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        
        let action = MemoEditorDetailNotification.requestFindLinkDetail(
            link: link
        )
        
        let newAction = DetailStackAction.tag(action)
        let update = DetailStackModel.update(
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
    
    func testSucceedDeleteMemo() throws {
        let address = Slashlink("/test")!
        
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: address, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-2")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-3")!, fallback: ""),
        ])

        let update = DetailStackModel.update(
            state: state,
            action: .succeedDeleteMemo(address),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            2,
            "Removes deleted detail"
        )
        
        XCTAssertEqual(update.state.details[0].address, Slashlink("/test-2")!)
        XCTAssertEqual(update.state.details[1].address, Slashlink("/test-3")!)
    }
    
    func testSucceedUpdateAudience() throws {
        let address = Slashlink("/test")!
        let updatedAddress = Slashlink(peer: .did(Did.local), slug: Slug("test")!)
        
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: address, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-2")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-3")!, fallback: ""),
        ])

        let update = DetailStackModel.update(
            state: state,
            action: .succeedUpdateAudience(
                MoveReceipt(
                    from: address,
                    to: updatedAddress
                )
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            3,
            "Preserves details"
        )
        
        // audience is now local
        XCTAssertEqual(update.state.details[0].address, updatedAddress)
        XCTAssertEqual(update.state.details[1].address, Slashlink("/test-2")!)
        XCTAssertEqual(update.state.details[2].address, Slashlink("/test-3")!)
    }
    
    func testSucceedMoveEntry() throws {
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: Slashlink("/test")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-2")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-3")!, fallback: ""),
        ])

        let address = Slashlink("/test-3")!
        let updatedAddress = Slashlink("/foo")!

        let update = DetailStackModel.update(
            state: state,
            action: .succeedMoveEntry(from: address, to: updatedAddress),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            3,
            "Preserves details"
        )
        
        XCTAssertEqual(update.state.details[0].address, Slashlink("/test")!)
        XCTAssertEqual(update.state.details[1].address, Slashlink("/test-2")!)
        // test-3 has become foo
        XCTAssertEqual(update.state.details[2].address, updatedAddress)
    }
    
    func testSucceedMergeEntry() throws {
        let address = Slashlink("/test-3")!
        let parent = Slashlink("/test-2")!
        
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: Slashlink("/test")!, fallback: ""),
            MemoDetailDescription.from(address: parent, fallback: ""),
            MemoDetailDescription.from(address: address, fallback: ""),
        ])

        let update = DetailStackModel.update(
            state: state,
            action: .succeedMergeEntry(
                parent: parent,
                child: address
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            3,
            "Preserves details"
        )
        
        XCTAssertEqual(update.state.details[0].address, Slashlink("/test")!)
        // test-3 has been turned into test-2
        XCTAssertEqual(update.state.details[1].address, parent)
        XCTAssertEqual(update.state.details[2].address, parent)
    }
}
