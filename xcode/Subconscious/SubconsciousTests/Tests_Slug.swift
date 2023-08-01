//
//  Tests_Slug.swift
//  Tests iOS
//
//  Created by Gordon Brander on 3/11/22.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

class Tests_Slug: XCTestCase {
    func testValid() throws {
        XCTAssertNotNil(Slug("valid-slug"))
        XCTAssertNotNil(Slug("oysters"))
        XCTAssertNotNil(Slug("SLUG"))
        XCTAssertNotNil(Slug("VALID_SLUG"))
        XCTAssertNotNil(Slug("-_-"))
    }
    
    func testVisibleInitializer() {
        XCTAssertNil(Slug(visible: "_test"))
        XCTAssertNil(Slug(visible: Slug.profile.description))
        XCTAssertNil(Slug(visible: "__test__"))
        XCTAssertNil(Slug(visible: "$__test__"))
        XCTAssertNil(Slug(visible: "_$__test__"))
        XCTAssertNil(Slug(visible: "$_$__test__"))
        XCTAssertNotNil(Slug(visible: "valid-slug"))
    }
    
    func testHiddenInitializer() {
        XCTAssertEqual(Slug(hidden: "test")!.description, "_test")
        XCTAssertEqual(Slug(hidden: "_test")!.description, "__test")
    }
    
    func testNotValid() throws {
        XCTAssertNil(Slug("/invalid-slug"))
        XCTAssertNil(Slug("@invalid-slug"))
        XCTAssertNil(Slug("invalid slug"))
        XCTAssertNil(Slug(" invalid-slug"))
        XCTAssertNil(Slug("//invalid-slug"))
        XCTAssertNil(Slug("invalid//slug"))
        XCTAssertNil(Slug("invalid-slug "))
        XCTAssertNil(Slug("invalid😈slug"))
    }
    
    func testDeep() throws {
        XCTAssertNotNil(Slug("valid/deep"))
        XCTAssertNotNil(Slug("valid/deep/slug"))
        XCTAssertNotNil(Slug("valid/-_-/___"))
    }

    func testNotValidDeep() throws {
        XCTAssertNil(Slug("valid//deep"))
        XCTAssertNil(Slug("valid/deep//slug"))
    }

    func testLosslessStringConvertable() throws {
        let slug = Slug("valid-slug")
        XCTAssertEqual(slug?.description, "valid-slug")
    }
    
    func testVerbatim() throws {
        let slug = Slug("VALID-slug")
        XCTAssertEqual(slug?.verbatim, "VALID-slug", "preserves case")
    }

    func testMarkup() throws {
        let slug = Slug("VALID-slug")
        XCTAssertEqual(slug?.markup, "/valid-slug")
        XCTAssertEqual(slug?.verbatimMarkup, "/VALID-slug")
    }

    func testSlugFromPathlike() throws {
        let pathlikeA = "foo.subtext"
        
        XCTAssertEqual(
            Slug(fromPath: pathlikeA, withExtension: "subtext"),
            Slug("foo")!
        )
        
        let pathlikeB = "foo-bar.subtext"
        XCTAssertEqual(
            Slug(fromPath: pathlikeB, withExtension: "subtext"),
            Slug("foo-bar")!
        )
        
        let pathlikeC = "foo-bar.txt"
        XCTAssertNil(
            Slug(fromPath: pathlikeC, withExtension: "subtext"),
            "Returns nil for invalid path extension"
        )
    }
    
    func testFormatStripsInvalidCharacters() throws {
        let slug = Slug(
            formatting: "The quick brown fox jumps over the lazy dog!@#$%^&*()+,>:;'|{}[]<>?"
        )
        XCTAssertEqual(
            slug?.description,
            "the-quick-brown-fox-jumps-over-the-lazy-dog",
            "Formats the string into a valid slug-string"
        )
    }
    
    func testFormatStripsLeadingUnderscores() throws {
        XCTAssertEqual(Slug(formatting: "_test")!.description, "test")
        XCTAssertEqual(Slug(formatting: "__test")!.description, "test")
        XCTAssertEqual(Slug(formatting: "__test__")!.description, "test__")
        XCTAssertEqual(Slug(formatting: "$___test__")!.description, "test__")
        XCTAssertEqual(Slug(formatting: "__$___test__")!.description, "test__")
        XCTAssertEqual(Slug(formatting: "$__$___test__")!.description, "test__")
    }
    
    func testFormatUnicodeCharacters() throws {
        let a = Slug(formatting: "Baháʼí")
        XCTAssertEqual(
            a?.description,
            "baháʼí"
        )
        let b = Slug(formatting: "Fédération Aéronautique Internationale")
        XCTAssertEqual(
            b?.description,
            "fédération-aéronautique-internationale"
        )
    }
    
    func testFormatLeavesUnderscoresIntact() throws {
        let slug = Slug(formatting: "The_quick_Brown_fOx")
        XCTAssertEqual(
            slug?.description,
            "the_quick_brown_fox",
            "Underscores allowed"
        )
    }
    
    func testFormatDropsDeepSlashes() throws {
        let slug = Slug(formatting: "the/quick brown/fox jumps")
        XCTAssertEqual(
            slug?.description,
            "thequick-brownfox-jumps",
            "Formats deep slug string into a valid slug-string"
        )
    }
    
    func testFormatTrimsEndOfString() throws {
        let slug = Slug(formatting: "the QuIck brown FOX ")
        XCTAssertEqual(
            slug?.description,
            "the-quick-brown-fox",
            "Trims string before sluggifying"
        )
    }
    
    func testFormatTrimsStringAfterRemovingInvalidCharacters() throws {
        let slug = Slug(formatting: "the QuIck brown FOX !$%")
        XCTAssertEqual(
            slug?.description,
            "the-quick-brown-fox",
            "Trims string after stripping characters"
        )
    }
    
    func testFormatTrimsNonAllowedAndWhitespaceBeforeSlashes() throws {
        let slug = Slug(formatting: "  /the QuIck brown FOX/ !$%")
        XCTAssertEqual(
            slug?.description,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }
    
    func testFormatCollapsesContiguousWhitespace() throws {
        let slug = Slug(formatting: "  the QuIck      brown FOX")
        XCTAssertEqual(
            slug?.description,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }
    
    func testToTitle() throws {
        let title = Slug("frozen-yogurt")!.toTitle()
        XCTAssertEqual(
            title,
            "Frozen yogurt",
            "Title-ifies slug and capitalizes first letter"
        )
    }
    
    func testToTitleCase() throws {
        let title = Slug("RAND-Corp")!.toTitle()
        XCTAssertEqual(
            title,
            "RAND Corp",
            "Title-ifies slug and preserves case"
        )
    }
    
    func testToTitleCase2() throws {
        let title = Slug("odd-CAPS")!.toTitle()
        XCTAssertEqual(
            title,
            "Odd CAPS",
            "Title-ifies slug and capitalizes first letter"
        )
    }
}
