//
//  Tests_LogFmt.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/16/23.
//

import XCTest
@testable import Subconscious

final class Tests_LogFmt: XCTestCase {
    func testFormat() throws {
        let string = LogFmt.format(
            metadata: [
                "code": "bar",
                "etc": "baz"
            ]
        )
        XCTAssertEqual(
            string,
            #"code="bar" etc="baz""#
        )
    }

    func testFormatEscaping() throws {
        let string = LogFmt.format(
            metadata: [
                "code": "bar",
                "etc": "baz"
            ]
        )
        XCTAssertEqual(
            string,
            #"code="bar" etc="baz""#
        )
    }
}
