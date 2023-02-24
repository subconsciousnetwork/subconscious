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
        guard let address = MemoAddress("local::slug") else {
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
        guard let address = MemoAddress("public::slug") else {
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
        XCTAssertNil(MemoAddress("badwrong::slug"))
        XCTAssertNil(MemoAddress("::slug"))
        XCTAssertNil(MemoAddress("nope::slug"))
        XCTAssertNil(MemoAddress("localbadwrong::slug"))
        XCTAssertNil(MemoAddress("publicbadwrong::slug"))
        XCTAssertNil(MemoAddress("xpublicx::slug"))
        XCTAssertNil(MemoAddress(" public::slug"))
        XCTAssertNil(MemoAddress(" local ::slug"))
        XCTAssertNil(MemoAddress(":: slug"))
        XCTAssertNil(MemoAddress("public:: slug"))
        XCTAssertNil(MemoAddress("local:: slug"))
        XCTAssertNil(MemoAddress("local::"))
        XCTAssertNil(MemoAddress("local::/slug"))
        XCTAssertNil(MemoAddress("local::slug/"))
        XCTAssertNil(MemoAddress("local::/slug/"))
    }
    
    func testEntryLinkExtensionTitle() throws {
        guard let link = EntryLink(
            title: "RAND Corporation",
            audience: .public
        ) else {
            XCTFail("Expected title to parse to slug successfully")
            return
        }
        XCTAssertEqual(
            link.title,
            "RAND Corporation",
            "Title matches title given"
        )
        XCTAssertEqual(
            String(link.address.slug),
            "rand-corporation",
            "Title is slugified correctly"
        )
    }

    func testEntryLinkExtensionDeepTitle() throws {
        guard let link = EntryLink(
            title: "A deep title/With children",
            audience: .public
        ) else {
            XCTFail("Expected title to parse to slug successfully")
            return
        }
        XCTAssertEqual(
            String(link.address.slug),
            "a-deep-title/with-children",
            "Title with slashes is converted to deep slug"
        )
    }
}
