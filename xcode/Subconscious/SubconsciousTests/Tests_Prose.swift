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
        XCTAssertEqual(text.title(), "I stuffed a shirt or two into my old carpet-bag, tucked it under my arm, and started for Cape Horn and the Pacific, quitting the good city o…")
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
}
