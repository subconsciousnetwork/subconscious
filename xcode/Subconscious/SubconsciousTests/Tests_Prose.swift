//
//  Tests_Prose.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/7/23.
//

import XCTest
@testable import Subconscious

final class Tests_Prose: XCTestCase {
    func testTitle() throws {
        let text = "I stuffed a shirt or two into my old carpet-bag, tucked it under my arm, and started for Cape Horn and the Pacific. Quitting the good city of old Manhatto, I duly arrived in New Bedford."
        XCTAssertEqual(text.title(), "I stuffed a shirt or two into my old carpet-bag, tucked it under my arm, and started for Cape Horn and the Pacific")
    }
    
    func testLongTitle() throws {
        let text = "I stuffed a shirt or two into my old carpet-bag, tucked it under my arm, and started for Cape Horn and the Pacific, quitting the good city of old Manhatto, to duly arrive in New Bedford."
        XCTAssertEqual(text.title(), "I stuffed a shirt or two into my old carpet-bag, tucked it under my arm, and started for Cape Horn and the Pacific, quitting the good city…")
    }
    
    func testTitleFallback() throws {
        let text = ""
        XCTAssertEqual(text.title(), "Untitled")
    }

    func testTitleFallback2() throws {
        let text = ""
        XCTAssertEqual(text.title(fallback: "Floop"), "Floop")
    }

    func testBangEndsSentence() throws {
        let text = "Lo! The sun is breaking through."
        XCTAssertEqual(text.title(), "Lo")
    }
    
    func testQuestion() throws {
        let text = "But what then? Methinks we have hugely mistaken this matter of Life and Death."
        XCTAssertEqual(text.title(), "But what then")
    }
    
    func testColonDoesNotEndSentence() throws {
        let text = #"Peleg said: "Now, Mr. Starbuck, are you sure everything is right?""#
        XCTAssertEqual(text.title(), #"Peleg said: "Now, Mr"#)
    }
    
    func testSemicolonDoesNotEndSentence() throws {
        let text = #"Spring, thou sheep-head; spring, and break thy backbone!""#
        XCTAssertEqual(text.title(), #"Spring, thou sheep-head; spring, and break thy backbone"#)
    }
    
    func testTruncate() throws {
        let text = "abcdefg"
        XCTAssertEqual(text.truncate(maxLength: 0), "")
        XCTAssertEqual(text.truncate(maxLength: 1), "")
        XCTAssertEqual(text.truncate(maxLength: 2), "a…")
        XCTAssertEqual(text.truncate(maxLength: 3), "ab…")
    }
    
    func testTruncateFallback() throws {
        let text = "abcdefg"
        XCTAssertEqual(text.truncate(
            maxLength: 1
        ), "")
        XCTAssertEqual(text.truncate(maxLength: 2), "a…")
        XCTAssertEqual(text.truncate(maxLength: 3), "ab…")
    }
}
