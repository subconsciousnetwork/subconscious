//
//  Tests_Slashlink.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/13/23.
//

import XCTest
@testable import Subconscious

final class Tests_Slashlink: XCTestCase {
    func testValid() throws {
        XCTAssertNotNil(Slashlink("@valid-petname/foo"))
        XCTAssertNotNil(Slashlink("@petname/foo-bar-baz-bing"))
        XCTAssertNotNil(Slashlink("@__valid-petname__/__foo__"))
        XCTAssertNotNil(Slashlink("@PETNAME/foo"))
        XCTAssertNotNil(Slashlink("/bar"))
        XCTAssertNotNil(Slashlink("@-_-/-_-"))
    }
    
    func testNotValid() throws {
        XCTAssertNil(Slashlink(""))
        XCTAssertNil(Slashlink("@bork/bad "))
        XCTAssertNil(Slashlink(" @bork/bad"))
        XCTAssertNil(Slashlink("@bork /bad"))
        XCTAssertNil(Slashlink("@bork/b ad"))
        XCTAssertNil(Slashlink("bork/bad"))
        XCTAssertNil(Slashlink("/bork bad"))
        XCTAssertNil(Slashlink("/bork@bad"))
        XCTAssertNil(Slashlink("@petname@foo-bar-baz-bing"))
        XCTAssertNil(Slashlink("@@bork/bad"))
        XCTAssertNil(Slashlink("@petname//foo-bar-baz-bing"))
        XCTAssertNil(Slashlink("invalid-slashlink"))
        XCTAssertNil(Slashlink("invalid$#%-slashlink"))
        XCTAssertNil(Slashlink("/special$#%-slashlink"))
        XCTAssertNil(Slashlink("/special  slashlink"))
        XCTAssertNil(Slashlink("//special-slashlink"))
        XCTAssertNil(Slashlink("/special//slashlink"))
        XCTAssertNil(Slashlink("/invalid😈petname"))
        XCTAssertNil(Slashlink("@invalid😈petname/foo"))
    }
    
    func testSlugOnly() throws {
        guard let slashlink = Slashlink("/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/valid-slashlink")
        XCTAssertEqual(slashlink.slug.description, "valid-slashlink")
        XCTAssertNil(slashlink.petname)
    }
    
    func testFull() throws {
        guard let slashlink = Slashlink("@valid-petname/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@valid-petname/valid-slashlink")
        XCTAssertEqual(slashlink.petname?.description, "valid-petname")
        XCTAssertEqual(slashlink.slug.description, "valid-slashlink")
    }
    
    func testUnicode() throws {
        guard let slashlink = Slashlink("@ⴙvalid-petname/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@ⴙvalid-petname/valid-slashlink")
        XCTAssertEqual(slashlink.petname?.description, "ⴙvalid-petname")
        XCTAssertEqual(slashlink.slug.description, "valid-slashlink")
    }
    
    func testUppercase() throws {
        guard let slashlink = Slashlink("@VALID-PETNAME/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@valid-petname/valid-slashlink")
        XCTAssertEqual(slashlink.verbatim, "@VALID-PETNAME/valid-slashlink")
        XCTAssertEqual(slashlink.petname?.verbatim, "VALID-PETNAME")
        XCTAssertEqual(slashlink.slug.description, "valid-slashlink")
    }
    
    func testDeepSlashlink() throws {
        guard let slashlink = Slashlink("@petname/deep/slashlinks/supported")
        else {
            XCTFail("Failed to parse deep slashlink")
            return
        }
        XCTAssertEqual(slashlink.slug.description, "deep/slashlinks/supported")
    }
    
    func testInvalidDoubleSlash() throws {
        XCTAssertNil(Slashlink("@bork//invalid-slashlink"))
        XCTAssertNil(Slashlink("@bork/invalid//deep/slashlink"))
    }

    func testPetnameOnlyInvalid() throws {
        XCTAssertNil(Slashlink("@only-petname-should-fail"))
    }
    
    func testToPetname() throws {
        let a = Slashlink("@foo/bar-baz")
        XCTAssertEqual(a?.toPetname(), Petname("foo"))
        
        let b = Slashlink("@FOO/BAR-baz")
        XCTAssertEqual(b?.toPetname(), Petname("FOO"))
        
        let c = Slashlink("/BAR-baz")
        XCTAssertNil(c!.toPetname())
    }
    
    func testsInitFromPetnameAndSlug() throws {
        guard let petname = Petname("foo") else {
            XCTFail("Could not create petname")
            return
        }
        guard let slug = Slug("bar-baz") else {
            XCTFail("Could not create slug")
            return
        }
        let slashlink = Slashlink(petname: petname, slug: slug)
        XCTAssertEqual(slashlink.description, "@foo/bar-baz")
    }

    func testsInitFromPetnameAndSlugCaps() throws {
        guard let petname = Petname("FOO") else {
            XCTFail("Could not create petname")
            return
        }
        guard let slug = Slug("BAR-baz") else {
            XCTFail("Could not create slug")
            return
        }
        let slashlink = Slashlink(petname: petname, slug: slug)
        XCTAssertEqual(slashlink.description, "@foo/bar-baz")
        XCTAssertEqual(slashlink.verbatim, "@FOO/BAR-baz")
        XCTAssertEqual(slashlink.petname?.verbatim, "FOO")
        XCTAssertEqual(slashlink.slug.verbatim, "BAR-baz")
    }

    func testsInitFromSlug() throws {
        guard let slug = Slug("bar-baz") else {
            XCTFail("Could not create slug")
            return
        }
        let slashlink = Slashlink(slug: slug)
        XCTAssertEqual(slashlink.description, "/bar-baz")
    }

    func testToSlug() throws {
        let a = Slashlink("@foo/bar-baz")
        XCTAssertEqual(a?.toSlug(), Slug("bar-baz"))
        
        let b = Slashlink("@FOO/BAR-baz")
        XCTAssertEqual(b?.toSlug(), Slug("BAR-baz"))
        
        let c = Slashlink("/BAR-baz")
        XCTAssertEqual(c?.toSlug(), Slug("BAR-baz"))
    }
}
