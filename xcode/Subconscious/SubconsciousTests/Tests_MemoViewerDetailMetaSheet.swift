//
//  Tests_MemoViewerDetailMetaSheet.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/7/23.
//

import XCTest
import ObservableStore
import Combine
@testable import Subconscious
@testable import SubconsciousCore

final class Tests_MemoViewerDetailMetaSheet: XCTestCase {
    func testSetAddress() throws {
        let state = MemoViewerDetailMetaSheetModel(
            address: nil
        )
        
        let address = Slashlink("@bob/foo")
        let update = MemoViewerDetailMetaSheetModel.update(
            state: state,
            action: .setAddress(address),
            environment: ()
        )
        
        XCTAssertEqual(update.state.address, address)
    }
}
