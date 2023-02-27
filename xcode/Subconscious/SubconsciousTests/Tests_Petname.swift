//
//  Tests_Petname.swift
//  Tests iOS
//
//  Created by Gordon Brander on 3/11/22.
//

import XCTest
@testable import Subconscious

class Tests_Petname: XCTestCase {
    func testValid() throws {
        XCTAssertNotNil(Petname("valid-petname"))
        XCTAssertNotNil(Petname("PETNAME"))
        XCTAssertNotNil(Petname("PET_NAME"))
        XCTAssertNotNil(Petname("-_-"))
    }
    
    func testNotValid() throws {
        XCTAssertNil(Petname("@invalid-petname"))
        XCTAssertNil(Petname("invalid petname"))
        XCTAssertNil(Petname(" invalid-petname"))
        XCTAssertNil(Petname("@@invalid-petname"))
        XCTAssertNil(Petname("invalid@petname"))
        XCTAssertNil(Petname("invalid-petname "))
        XCTAssertNil(Petname("invalid😈petname"))
    }
    
    func testLosslessStringConvertable() throws {
        let a = Petname("valid-petname")
        XCTAssertEqual(a?.description, "valid-petname")
    }
    
    func testVerbatim() throws {
        let b = Petname("VALID-petname")
        XCTAssertEqual(b?.verbatim, "VALID-petname", "preserves case")
    }
    
    func testValidUnicodeCharacters() throws {
        let a = Petname("Baháʼí")
        XCTAssertEqual(a?.description, "baháʼí")
        XCTAssertEqual(a?.verbatim, "Baháʼí")

        let b = Petname("Fédération-Aéronautique-Internationale")
        XCTAssertEqual(b?.description, "fédération-aéronautique-internationale")
        XCTAssertEqual(b?.verbatim, "Fédération-Aéronautique-Internationale")
    }

    func testIdentifiable() throws {
        let a = Petname("VALID-petname")
        let b = Petname("vaLId-petname")
        XCTAssertEqual(a?.id, b?.id)
    }
    
    func testNormalized() throws {
        let a = Petname("VALID-petname")
        let b = Petname("vaLId-petname")
        XCTAssertEqual(a?.description, b?.description)
    }
    
    func testMarkup() throws {
        let petname = Petname("VALID-petname")
        XCTAssertEqual(petname?.markup, "@VALID-petname")
    }
    
    func testFormatStripsInvalidCharacters() throws {
        let petname = Petname(
            formatting: "The quick brown fox jumps over the lazy dog!@#$%^&*()+,>:;'|{}[]<>?"
        )
        XCTAssertEqual(
            petname?.description,
            "the-quick-brown-fox-jumps-over-the-lazy-dog",
            "Formats the string into a valid slug-string"
        )
    }
    
    func testFormatTrimsEndOfString() throws {
        let petname = Petname(formatting: "the QuIck brown FOX ")
        XCTAssertEqual(
            petname?.description,
            "the-quick-brown-fox",
            "Trims string before sluggifying"
        )
    }
    
    func testFormatTrimsStringAfterRemovingInvalidCharacters() throws {
        let petname = Petname(formatting: "the QuIck brown FOX !$%")
        XCTAssertEqual(
            petname?.description,
            "the-quick-brown-fox",
            "Trims string after stripping characters"
        )
    }
    
    func testFormatTrimsNonAllowedAndWhitespaceBeforeSlashes() throws {
        let petname = Petname(formatting: "  /the QuIck brown FOX/ !$%")
        XCTAssertEqual(
            petname?.description,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }
    
    func testFormatCollapsesContiguousWhitespace() throws {
        let petname = Petname(formatting: "  @the QuIck      brown FOX")
        XCTAssertEqual(
            petname?.description,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }
}