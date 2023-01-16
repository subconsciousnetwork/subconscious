//
//  Tests_Slashlink.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/13/23.
//

import XCTest
@testable import Subconscious

final class Tests_Slashlink: XCTestCase {
    func testPetnameOnly() throws {
        guard let slashlink = Slashlink("@valid-petname") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@valid-petname")
        XCTAssertEqual(slashlink.petname, "@valid-petname")
        XCTAssertNil(slashlink.slug)
    }
    
    func testSlugOnly() throws {
        guard let slashlink = Slashlink("/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/valid-slashlink")
        XCTAssertNil(slashlink.petname)
        XCTAssertEqual(slashlink.slug, "/valid-slashlink")
    }
    
    func testFull() throws {
        guard let slashlink = Slashlink("@valid-petname/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@valid-petname/valid-slashlink")
        XCTAssertEqual(slashlink.petname, "@valid-petname")
        XCTAssertEqual(slashlink.slug, "/valid-slashlink")
    }
    
    func testUnicode() throws {
        guard let slashlink = Slashlink("@ⴙvalid-petname/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@ⴙvalid-petname/valid-slashlink")
        XCTAssertEqual(slashlink.petname, "@ⴙvalid-petname")
        XCTAssertEqual(slashlink.slug, "/valid-slashlink")
    }
    
    func testInvalidSlashlinkA() throws {
        let slashlink = Slashlink("invalid-slashlink")
        XCTAssertNil(slashlink, "Rejects slashlink without valid leading character")
    }
    
    func testInvalidSlashlinkB() throws {
        let slashlink = Slashlink("invalid$#%-slashlink")
        XCTAssertNil(slashlink, "Rejects slashlink without valid leading character")
    }
    
    func testFormatInvalidSlashlink() throws {
        guard let slashlink = Slashlink("/special$#%-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special-slashlink")
        XCTAssertNil(slashlink.petname)
        XCTAssertEqual(slashlink.slug, "/special-slashlink")
    }
    
    func testFormatSlashlinkSpaces() throws {
        guard let slashlink = Slashlink("/special  slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special--slashlink")
        XCTAssertNil(slashlink.petname)
        XCTAssertEqual(slashlink.slug, "/special--slashlink")
    }
    
    func testFormatSlashlinkDoubleSlashA() throws {
        guard let slashlink = Slashlink("//special-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special-slashlink")
        XCTAssertNil(slashlink.petname)
        XCTAssertEqual(slashlink.slug, "/special-slashlink")
    }
    
    func testFormatSlashlinkDoubleSlashB() throws {
        guard let slashlink = Slashlink("/special//slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special/slashlink")
        XCTAssertNil(slashlink.petname)
        XCTAssertEqual(slashlink.slug, "/special/slashlink")
    }
}
