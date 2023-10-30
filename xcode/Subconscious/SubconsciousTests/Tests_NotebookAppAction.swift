//
//  Tests_Notebook+AppAction.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/20/23.
//

import XCTest

@testable import Subconscious

final class Tests_Notebook_AppAction: XCTestCase {
    func testFromRequestDeleteMemo() throws {
        let action = AppAction.from(
            NotebookAction.requestDeleteMemo(
                Slashlink("/bob")!
            )
        )
        XCTAssertEqual(action, .deleteMemo(Slashlink("/bob")!))
    }
}
