//
//  Tests_SubtextAttributedStringRenderer.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/8/23.
//

import XCTest
@testable import Subconscious

final class Tests_SubtextAttributedStringRendererToURL: XCTestCase {
    func testSubSlashlinkToURL() throws {
        let link = SubSlashlinkURL(
            slashlink: Slashlink("@here/lo-and-behold")!,
            title: "Lo! And Behold"
        )
        
        guard let url = link.toURL() else {
            XCTFail("Failed to construct URL from link")
            return
        }
        
        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            XCTFail("Failed to parse URL components")
            return
        }
        
        XCTAssertEqual(components.scheme, "sub")
        XCTAssertEqual(components.host, "slashlink")
        XCTAssertEqual(
            components.firstQueryValueWhere(name: "slashlink"),
            "@here/lo-and-behold"
        )
        XCTAssertEqual(
            components.firstQueryValueWhere(name: "title"),
            "Lo! And Behold"
        )
    }
    
    func testSubSlashlinkFromURL() throws {
        let url = URL(string: "sub://slashlink?slashlink=@foo/bar&title=Bar")!
        
        guard let link = url.toSubSlashlinkURL() else {
            XCTFail("Failed to construct SubSlashlinkURL from URL")
            return
        }
        
        XCTAssertEqual(link.slashlink.description, "@foo/bar")
        XCTAssertEqual(link.title, "Bar")
    }
    
    
}
