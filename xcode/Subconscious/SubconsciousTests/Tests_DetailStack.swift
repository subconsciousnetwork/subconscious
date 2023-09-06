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
}
