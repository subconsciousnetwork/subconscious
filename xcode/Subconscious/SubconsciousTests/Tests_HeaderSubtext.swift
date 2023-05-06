//
//  Tests_HeaderSubtext.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/6/23.
//

import XCTest
@testable import Subconscious

final class Tests_HeaderSubtext: XCTestCase {
    func testSize() throws {
        let now = Date.now
        
        let headerSubtext = HeaderSubtext(
            headers: [
                Header(name: "Content-Type", value: "text/subtext"),
                Header(name: "Created", value: now.ISO8601Format()),
                Header(name: "Modified", value: now.ISO8601Format())
            ],
            body: "Baz"
        )
        
        guard let headerSubtextSize = headerSubtext.size() else {
            XCTFail("Failed to get size")
            return
        }
        
        let plain = """
        Content-Type: text/subtext
        Created: \(now.ISO8601Format())
        Modified: \(now.ISO8601Format())
        
        Baz
        """
        
        guard let plainSize = plain.data(using: .utf8)?.count else {
            XCTFail("Failed to get size for plain text control case")
            return
        }
        
        XCTAssertEqual(headerSubtextSize, plainSize)
    }
}
