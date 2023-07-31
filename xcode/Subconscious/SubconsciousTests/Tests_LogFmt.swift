//
//  Tests_LogFmt.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/16/23.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

final class Tests_LogFmt: XCTestCase {
    func testFormat() throws {
        let string = LogFmt.format(
            message: "Foo",
            metadata: [
                "code": "bar",
                "etc": "baz"
            ]
        )
        XCTAssertEqual(
            string,
            #"msg="Foo" code="bar" etc="baz""#
        )
    }

    func testFormatEscaping() throws {
        let string = LogFmt.format(
            message: #""Foo""#,
            metadata: [
                "code": "bar",
                "etc": "baz"
            ]
        )
        XCTAssertEqual(
            string,
            #"msg="\"Foo\"" code="bar" etc="baz""#
        )
    }
}
