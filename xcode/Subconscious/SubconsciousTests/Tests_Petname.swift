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
        XCTAssertNotNil(Petname("bob"))
        XCTAssertNotNil(Petname("valid-petname"))
        XCTAssertNotNil(Petname("PETNAME"), "Case-insensitive")
        XCTAssertNotNil(Petname("PET_NAME"), "Case-insensitive")
        XCTAssertNotNil(Petname("-_-"))
        XCTAssertNotNil(Petname("alice.bob"))
        XCTAssertNotNil(Petname("dan.charlie.bob.alice"))
        XCTAssertNotNil(Petname("bob-foo.alice-foo"))
        XCTAssertNotNil(Petname("bob_foo.alice_foo"))
    }
    
    func testNotValid() throws {
        XCTAssertNil(Petname(""))
        XCTAssertNil(Petname("@invalid-petname"))
        XCTAssertNil(Petname("invalid petname"))
        XCTAssertNil(Petname(" invalid-petname"))
        XCTAssertNil(Petname("@@invalid-petname"))
        XCTAssertNil(Petname("invalid@petname"))
        XCTAssertNil(Petname("invalid-petname "))
        XCTAssertNil(Petname("invalid😈petname"))
        XCTAssertNil(Petname("eve...alice"))
        XCTAssertNil(Petname("eve.alice..bob"))
        XCTAssertNil(Petname(".eve.alice"))
        XCTAssertNil(Petname("alice.eve."))
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
        XCTAssertEqual(petname?.markup, "@valid-petname")
        XCTAssertEqual(petname?.verbatimMarkup, "@VALID-petname")
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
    
    func testIncrementBasePetname() throws {
        let petname = Petname("ziggy")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "ziggy-1"
        )
    }
    
    func testIncrementTrailingDash() throws {
        let petname = Petname("rodrigo-")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "rodrigo-1"
        )
    }
    
    func testIncrementTrailingDashes() throws {
        let petname = Petname("james-baxter------")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "james-baxter------1"
        )
    }
    
    func testIncrementTrailingNumbers() throws {
        let petname = Petname("django999")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "django999-1"
        )
    }
    
    func testIncrementExistingSuffix() throws {
        let petname = Petname("princess-arabella-3")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "princess-arabella-4"
        )
    }
    
    func testIncrementDoubleDigitSuffix() throws {
        let petname = Petname("xxx-31")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "xxx-32"
        )
    }
    
    func testIncrementExtremelyLargeSuffix() throws {
        let petname = Petname("ben-9999")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "ben-10000"
        )
    }
    
    func testAppend() throws {
        let alice = Petname("alice")!
        let bob = Petname("BOB")!
        let path = alice.append(petname: bob)
        XCTAssertEqual(path.description, "bob.alice")
        XCTAssertEqual(path.verbatim, "BOB.alice")
    }
    
    func testStringToPetname() throws {
        XCTAssertEqual("alice".toPetname(), Petname("alice")!)
        XCTAssertNil("$EVE".toPetname())
    }
}
