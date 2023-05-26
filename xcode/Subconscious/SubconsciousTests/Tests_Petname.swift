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
        let petname = Petname.Name(formatting: "  @the QuIck      brown FOX")
        XCTAssertEqual(
            petname?.description,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }
    
    func testIncrementBasePetname() throws {
        let petname = Petname.Name("ziggy")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "ziggy-1"
        )
    }
    
    func testIncrementTrailingDash() throws {
        let petname = Petname.Name("rodrigo-")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "rodrigo-1"
        )
    }
    
    func testIncrementTrailingDashes() throws {
        let petname = Petname.Name("james-baxter------")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "james-baxter------1"
        )
    }
    
    func testIncrementTrailingNumbers() throws {
        let petname = Petname.Name("django999")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "django999-1"
        )
    }
    
    func testIncrementExistingSuffix() throws {
        let petname = Petname.Name("princess-arabella-3")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "princess-arabella-4"
        )
    }
    
    func testIncrementDoubleDigitSuffix() throws {
        let petname = Petname.Name("xxx-31")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "xxx-32"
        )
    }
    
    func testIncrementExtremelyLargeSuffix() throws {
        let petname = Petname.Name("ben-9999")!
        let next = petname.increment()
        
        XCTAssertEqual(
            next?.description,
            "ben-10000"
        )
    }
    
    func testAppendPart() throws {
        let alice = Petname("alice")!
        let bob = Petname.Name("BOB")!
        guard let path = alice.append(name: bob) else {
            XCTFail("append failed")
            return
        }
        XCTAssertEqual(path.description, "bob.alice")
        XCTAssertEqual(path.verbatim, "BOB.alice")
    }
    
    func testAppend() throws {
        let alice = Petname("alice")!
        let bob = Petname("BOB")!
        guard let path = alice.append(petname: bob) else {
            XCTFail("append failed")
            return
        }
        XCTAssertEqual(path.description, "bob.alice")
        XCTAssertEqual(path.verbatim, "BOB.alice")
    }
    
    func testComplexAppend() throws {
        let a = Petname("alice.charlie")!
        let b = Petname("BOB.ron")!
        guard let path = a.append(petname: b) else {
            XCTFail("append failed")
            return
        }
        XCTAssertEqual(path.description, "bob.ron.alice.charlie")
        XCTAssertEqual(path.verbatim, "BOB.ron.alice.charlie")
    }
    
    
    func testLeaf() throws {
        let a = Petname("alice.bob.charlie")!
        XCTAssertEqual(a.leaf, Petname.Name("alice")!)
        
        let b = Petname("bob.charlie")!
        XCTAssertEqual(b.leaf, Petname.Name("bob")!)
        
        let c = Petname("charlie")!
        XCTAssertEqual(c.leaf, Petname.Name("charlie")!)
    }
    
    func testRoot() throws {
        let a = Petname("alice.bob.charlie")!
        XCTAssertEqual(a.root, Petname.Name("charlie")!)
        
        let b = Petname("charlie.bob")!
        XCTAssertEqual(b.root, Petname.Name("bob")!)
        
        let c = Petname("charlie")!
        XCTAssertEqual(c.root, Petname.Name("charlie")!)
    }
}
