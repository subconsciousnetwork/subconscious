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
    }
    
    func testSlugOnly() throws {
        guard let slashlink = Slashlink("/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/valid-slashlink")
    }
    
    func testFull() throws {
        guard let slashlink = Slashlink("@valid-petname/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@valid-petname/valid-slashlink")
    }
    
    func testUnicode() throws {
        guard let slashlink = Slashlink("@ⴙvalid-petname/valid-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "@ⴙvalid-petname/valid-slashlink")
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
        guard let slashlink = Slashlink(formatting: "/special$#%-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special-slashlink")
    }
    
    func testFormatSlashlinkSpaces() throws {
        guard let slashlink = Slashlink(formatting: "/special  slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special--slashlink")
    }
    
    func testFormatSlashlinkDoubleSlashA() throws {
        guard let slashlink = Slashlink(formatting: "//special-slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special-slashlink")
    }
    
    func testFormatSlashlinkDoubleSlashB() throws {
        guard let slashlink = Slashlink(formatting: "/special//slashlink") else {
            XCTFail("Failed to parse slashlink")
            return
        }
        XCTAssertEqual(slashlink.description, "/special/slashlink")
    }
}
