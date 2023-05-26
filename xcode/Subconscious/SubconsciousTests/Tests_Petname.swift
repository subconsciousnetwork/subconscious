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
        XCTAssertNotNil(Petname.Name("bob"))
        XCTAssertNotNil(Petname.Name("valid-petname"))
        XCTAssertNotNil(Petname.Name("PETNAME"), "Case-insensitive")
        XCTAssertNotNil(Petname.Name("PET_NAME"), "Case-insensitive")
        XCTAssertNotNil(Petname.Name("-_-"))
        XCTAssertNotNil(Petname.Name("bob_foo"))
        
        XCTAssertNotNil(Petname("bob"))
        XCTAssertNotNil(Petname("valid-petname"))
        XCTAssertNotNil(Petname("PETNAME"), "Case-insensitive")
        XCTAssertNotNil(Petname("PET_NAME"), "Case-insensitive")
        XCTAssertNotNil(Petname("-_-"))
        XCTAssertNotNil(Petname("alice.bob"))
        XCTAssertNotNil(Petname("dan.charlie.bob.alice"))
        XCTAssertNotNil(Petname("bob-foo.alice-foo"))
        XCTAssertNotNil(Petname("bob_foo.alice_foo"))
        XCTAssertNotNil(Petname("alice.bob.eve.charlie.bob"))
    }
    
    func testNotValid() throws {
        XCTAssertNil(Petname.Name(""))
        XCTAssertNil(Petname.Name("@invalid-petname"))
        XCTAssertNil(Petname.Name("invalid petname"))
        XCTAssertNil(Petname.Name(" invalid-petname"))
        XCTAssertNil(Petname.Name("@@invalid-petname"))
        XCTAssertNil(Petname.Name("invalid@petname"))
        XCTAssertNil(Petname.Name("invalid-petname "))
        XCTAssertNil(Petname.Name("invalid😈petname"))
        XCTAssertNil(Petname.Name(".alice"))
        XCTAssertNil(Petname.Name("alice.eve"))
        XCTAssertNil(Petname.Name("eve...alice"))
        XCTAssertNil(Petname.Name("eve.alice..bob"))
        XCTAssertNil(Petname.Name(".eve.alice"))
        XCTAssertNil(Petname.Name("alice.eve."))
        
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
        let a = Petname.Name("valid-petname")
        XCTAssertEqual(a?.description, "valid-petname")
        
        let b = Petname("valid-petname.this-is-me")
        XCTAssertEqual(b?.description, "valid-petname.this-is-me")
    }
    
    func testVerbatim() throws {
        let a = Petname.Name("VALID-petname")
        XCTAssertEqual(a?.verbatim, "VALID-petname", "preserves case")
        
        let b = Petname("VALID-petname.this_IS_me")
        XCTAssertEqual(b?.verbatim, "VALID-petname.this_IS_me", "preserves case")
    }
    
    func testValidUnicodeCharacters() throws {
        let a = Petname.Name("Baháʼí")
        XCTAssertEqual(a?.description, "baháʼí")
        XCTAssertEqual(a?.verbatim, "Baháʼí")
        
        let b = Petname.Name("Fédération-Aéronautique-Internationale")
        XCTAssertEqual(b?.description, "fédération-aéronautique-internationale")
        XCTAssertEqual(b?.verbatim, "Fédération-Aéronautique-Internationale")
        
        let c = Petname("Ba.háʼí")
        XCTAssertEqual(c?.description, "ba.háʼí")
        XCTAssertEqual(c?.verbatim, "Ba.háʼí")
        
        let d = Petname("Fédération-Aéronau.tique-Internationale")
        XCTAssertEqual(d?.description, "fédération-aéronau.tique-internationale")
        XCTAssertEqual(d?.verbatim, "Fédération-Aéronau.tique-Internationale")
    }
    
    func testIdentifiable() throws {
        let a = Petname.Name("VALID-petname")
        let b = Petname.Name("vaLId-petname")
        XCTAssertEqual(a?.id, b?.id)
        
        let c = Petname("VALID-petname.MORE-parts")
        let d = Petname("vaLId-petname.MorE-paRTs")
        XCTAssertEqual(c?.id, d?.id)
    }
    
    func testNormalized() throws {
        let a = Petname.Name("VALID-petname")
        let b = Petname.Name("vaLId-petname")
        XCTAssertEqual(a?.description, b?.description)
        
        let c = Petname("VALID-petname.MORE-parts")
        let d = Petname("vaLId-petname.MorE-paRTs")
        XCTAssertEqual(c?.description, d?.description)
    }
    
    func testMarkup() throws {
        let name = Petname.Name("VALID-petname")
        XCTAssertEqual(name?.markup, "@valid-petname")
        XCTAssertEqual(name?.verbatimMarkup, "@VALID-petname")
        
        let petname = Petname("VALID-petname.MORE-parts")
        XCTAssertEqual(petname?.markup, "@valid-petname.more-parts")
        XCTAssertEqual(petname?.verbatimMarkup, "@VALID-petname.MORE-parts")
    }
    
    func testFormatStripsInvalidCharacters() throws {
        let name = Petname.Name(
            formatting: "The quick brown fox jumps over the lazy dog!@#$%^&*()+,>:;'|{}[]<>?"
        )
        XCTAssertEqual(
            name?.description,
            "the-quick-brown-fox-jumps-over-the-lazy-dog",
            "Formats the string into a valid slug-string"
        )
        
        let petname = Petname(
            formatting: "The quick brown fox!@#$%^&*()+,>:;'|{}[]<>?. jumps over the lazy dog!@#$%^&*()+,>:;'|{}[]<>?"
        )
        XCTAssertEqual(
            petname?.description,
            "the-quick-brown-fox.jumps-over-the-lazy-dog",
            "Formats the string into a valid slug-string"
        )
    }
    
    func testFormatTrimsEndOfString() throws {
        let name = Petname.Name(formatting: "the QuIck brown FOX ")
        XCTAssertEqual(
            name?.description,
            "the-quick-brown-fox",
            "Trims string before sluggifying"
        )
        
        let petname = Petname(formatting: "the QuIck .brown FOX ")
        XCTAssertEqual(
            petname?.description,
            "the-quick.brown-fox",
            "Trims string before sluggifying"
        )
    }
    
    func testFormatTrimsStringAfterRemovingInvalidCharacters() throws {
        let name = Petname.Name(formatting: "the QuIck brown FOX !$%")
        XCTAssertEqual(
            name?.description,
            "the-quick-brown-fox",
            "Trims string after stripping characters"
        )
        
        let petname = Petname(formatting: "the QuIck .brown FOX !$%")
        XCTAssertEqual(
            petname?.description,
            "the-quick.brown-fox",
            "Trims string after stripping characters"
        )
    }
    
    func testFormatTrimsNonAllowedAndWhitespaceBeforeSlashes() throws {
        let petname = Petname.Name(formatting: "  /the QuIck brown FOX/ !$%")
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
    
    func testParts() {
        let a = Petname.Name("alice")!
        let b = Petname.Name("bob")!
        let c = Petname.Name("charlie")!
        
        let name = Petname(parts: [a, b, c])
        
        XCTAssertEqual(name?.description, "alice.bob.charlie")
    }
    
    func testRejectsEmptyParts() {
        XCTAssertNil(Petname(parts: []))
        XCTAssertNil(Petname("..."))
    }
    
    func testPart() {
        let a = Petname.Name("alice")!
        let name = Petname(name: a)
        
        XCTAssertEqual(name.description, "alice")
    }
}
