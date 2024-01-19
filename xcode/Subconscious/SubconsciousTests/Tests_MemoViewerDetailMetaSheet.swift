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

final class Tests_MemoViewerDetailMetaSheet: XCTestCase {
    func testSetAddress() throws {
        let state = MemoViewerDetailMetaSheetModel(
            address: nil
        )
        
        let address = Slashlink("@bob/foo")!
        let update = MemoViewerDetailMetaSheetModel.update(
            state: state,
            action: .setAddress(address),
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(update.state.address, address)
    }
    
    func testSetAuthor() throws {
        let state = MemoViewerDetailMetaSheetModel(
            address: nil
        )
        
        let author = UserProfile.dummyData()
        let update = MemoViewerDetailMetaSheetModel.update(
            state: state,
            action: .setAuthor(author),
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(update.state.author, author)
    }
}
