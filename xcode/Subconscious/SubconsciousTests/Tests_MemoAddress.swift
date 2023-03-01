//
//  Tests_MemoAddress.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/23/23.
//

import XCTest
@testable import Subconscious

final class Tests_MemoAddress: XCTestCase {
    func testMemoAddressParseA() throws {
        guard let address = MemoAddress("local::/slug") else {
            XCTFail("Failed to parse valid address string")
            return
        }
        switch address {
        case .local:
            break
        default:
            XCTFail("Parsed type incorrectly")
        }
        XCTAssertEqual(address.slug, Slug("slug")!)
    }
    
    func testMemoAddressParseB() throws {
        guard let address = MemoAddress("public::/slug") else {
            XCTFail("Failed to parse valid address string")
            return
        }
        switch address {
        case .public:
            break
        default:
            XCTFail("Parsed type incorrectly")
        }
        XCTAssertEqual(address.slug, Slug("slug")!)
    }
    
    func testMemoAddressParseBadAddress() throws {
        XCTAssertNil(MemoAddress("public::slug"))
        XCTAssertNil(MemoAddress("local::slashlink"))
        XCTAssertNil(MemoAddress("::/slug"))
        XCTAssertNil(MemoAddress("nope::/slug"))
        XCTAssertNil(MemoAddress("localbadwrong::slug"))
        XCTAssertNil(MemoAddress("publicbadwrong::slug"))
        XCTAssertNil(MemoAddress("xpublicx::slug"))
        XCTAssertNil(MemoAddress(" public::slug"))
        XCTAssertNil(MemoAddress(" local ::slug"))
        XCTAssertNil(MemoAddress(":: slug"))
        XCTAssertNil(MemoAddress("public:: slug"))
        XCTAssertNil(MemoAddress("local:: slug"))
        XCTAssertNil(MemoAddress("local::"))
        XCTAssertNil(MemoAddress("local::@foo/slug"))
        XCTAssertNil(MemoAddress("local::slug/"))
        XCTAssertNil(MemoAddress("local::/slug/"))
    }
}
