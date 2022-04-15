//
//  Test_Markup.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/15/22.
//

import XCTest
@testable import Subconscious

class Test_Markup: XCTestCase {
    func testWikilinkLosslessStringConvertable() throws {
        let markup = Markup.Wikilink("[[Wikilink]]")!
        XCTAssertEqual(
            String(markup),
            "[[Wikilink]]",
            "Losslessly converts to/from string"
        )
    }

    func testWikilinkMarkupWithoutClosingTag() throws {
        let markup = Markup.Wikilink("[[Wikilink]]")!
        XCTAssertEqual(
            String(markup.markupWithoutClosingTag),
            "[[Wikilink",
            "markupWithoutClosingTag drops closing tag"
        )
    }

    func testBoldLosslessStringConvertable() throws {
        guard let markup = Markup.Bold("*bold*") else {
            XCTFail("Expected Bold")
            return
        }
        XCTAssertEqual(
            String(markup),
            "*bold*",
            "Losslessly converts to/from string"
        )
    }

    func testBoldMarkupWithoutClosingTag() throws {
        guard let markup = Markup.Bold("*bold*") else {
            XCTFail("Expected Bold")
            return
        }
        XCTAssertEqual(
            String(markup.markupWithoutClosingTag),
            "*bold",
            "markupWithoutClosingTag drops closing tag"
        )
    }

    func testItalicLosslessStringConvertable() throws {
        guard let markup = Markup.Italic("_italic_") else {
            XCTFail("Expected Italic")
            return
        }
        XCTAssertEqual(
            String(markup),
            "_italic_",
            "Losslessly converts to/from string"
        )
    }

    func testItalicMarkupWithoutClosingTag() throws {
        guard let markup = Markup.Italic("_italic_") else {
            XCTFail("Expected Italic")
            return
        }
        XCTAssertEqual(
            String(markup.markupWithoutClosingTag),
            "_italic",
            "markupWithoutClosingTag drops closing tag"
        )
    }
}
