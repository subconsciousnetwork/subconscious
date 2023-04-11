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
    var cancellables: Set<AnyCancellable> = Set()
    
    override func setUp() {
        self.cancellables = Set()
    }
    
    class MockPasteboard: PasteboardProtocol {
        private(set) var copies: Int = 0
        private(set) var store: String?
        
        var string: String? {
            get {
                store
            }
            set {
                store = newValue
                copies = copies + 1
            }
        }
    }
    
    func testSetAddress() throws {
        let environment = MockPasteboard()
        
        let state = MemoViewerDetailMetaSheetModel(
            address: nil
        )
        
        let address = MemoAddress("public::@bob/foo")
        let update = MemoViewerDetailMetaSheetModel.update(
            state: state,
            action: .setAddress(address),
            environment: environment
        )
        
        XCTAssertEqual(update.state.address, address)
    }
    
    func testCopyLink() throws {
        let environment = MockPasteboard()
        
        let state = MemoViewerDetailMetaSheetModel(
            address: MemoAddress("public::@bob/foo")
        )
        
        let update = MemoViewerDetailMetaSheetModel.update(
            state: state,
            action: .copyLink,
            environment: environment
        )
        
        XCTAssertEqual(environment.string, "@bob/foo")
        XCTAssertEqual(environment.copies, 1)
        
        let expectation = XCTestExpectation(
            description: "Sends dismiss fx"
        )
        
        update.fx.sink(receiveValue: { action in
            if case .requestDismiss = action {
                expectation.fulfill()
            }
        }).store(in: &cancellables)
        
        wait(for: [expectation], timeout: 0.2)
    }
}
