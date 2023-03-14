//
//  Tests_Memo.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/15/23.
//

import XCTest
@testable import Subconscious

final class Tests_Memo: XCTestCase {
    func testMemoMerge() {
        let a = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [
                Header(name: "Foo", value: "Foo")
            ],
            body: "Example A"
        )
        
        let b = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.text.fileExtension,
            additionalHeaders: [
                Header(name: "Bar", value: "Bar"),
                Header(name: "Foo", value: "Bad")
            ],
            body: "Example B"
        )
        
        let c = a.merge(b)
        
        // Test that A's headers win
        XCTAssertEqual(c.fileExtension, a.fileExtension, "Keeps subject file extension")
        
        // Test that additional headers are merged
        XCTAssertEqual(c.additionalHeaders.count, 2, "Merges headers")
        let foo = c.additionalHeaders.get(first: "Foo")
        XCTAssertEqual(foo, "Foo", "Merges headers")
        
        XCTAssertEqual(
            c.body,
            "Example A\n\nExample B",
            "Concatenates bodies"
        )
    }
    
    func testMemoDraftDefaults() throws {
        let draft = Memo.draft(body: "Foo")
        XCTAssertEqual(draft.body, "Foo")
        XCTAssertEqual(draft.contentType, ContentType.subtext.rawValue)
        XCTAssertEqual(draft.modified.ISO8601Format(), Date.now.ISO8601Format())
        XCTAssertEqual(draft.created.ISO8601Format(), Date.now.ISO8601Format())
    }
    
    func testMemoDraftCustom() throws {
        let date = Date.distantPast
        let draft = Memo.draft(
            contentType: .text,
            created: date,
            modified: date,
            body: "Foo"
        )
        XCTAssertEqual(draft.body, "Foo")
        XCTAssertEqual(draft.contentType, ContentType.text.rawValue)
        XCTAssertEqual(draft.modified, date)
        XCTAssertEqual(draft.created, date)
    }
}
