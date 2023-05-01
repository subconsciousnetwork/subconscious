//
//  Tests_MemoViewerDetailView.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 1/5/2023.
//

import XCTest
import ObservableStore
import Combine
@testable import Subconscious

final class Tests_MemoViewerDetailView: XCTestCase {
    func testRequestFindDetail() throws {
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        guard let url = link.toURL() else {
            XCTFail("Failed to build URL")
            return
        }
        
        let action = MemoViewerDetailLoadedView.requestFindDetail(
            address: Slashlink(petname: Petname("origin")!).toPublicMemoAddress(),
            url: url
        )
        
        switch action {
        case .requestFindDetail(let slashlink, _):
            guard let petname = slashlink.petname else {
                XCTFail("Failed to find petname")
                return
            }
            
            XCTAssertEqual(petname, Petname("bob.alice.origin")!)
        case _:
            XCTFail("Wrong action")
            return
        }
    }
}
