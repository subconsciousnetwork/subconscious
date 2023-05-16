//
//  Tests_URLUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/22/23.
//

import XCTest
@testable import Subconscious

final class Tests_URLUtilities: XCTestCase {
    func testIsHTTP() throws {
        let urlA = URL(string: "http://example.com")!
        XCTAssertTrue(urlA.isHTTP())

        let urlB = URL(string: "https://example.com")!
        XCTAssertTrue(urlB.isHTTP())

        let urlC = URL(string: "ftp://example.com")!
        XCTAssertFalse(urlC.isHTTP())

        let urlD = URL(string: "file://example.com")!
        XCTAssertFalse(urlD.isHTTP())
    }
    
    func testValidURL() {
        let urlString = "https://example.com/image.jpg"
        let url = URL(validatedString: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }
    
    func testInvalidURL() {
        let urlString = "not a url"
        let url = URL(validatedString: urlString)
        XCTAssertNil(url)
    }
    
    func testInvalidScheme() {
        let urlString = "ftp://example.com/image.jpg"
        let url = URL(validatedString: urlString)
        XCTAssertNil(url)
    }
    
    func testMissingHost() {
        let urlString = "https:///image.jpg"
        let url = URL(validatedString: urlString)
        XCTAssertNil(url)
    }
    
    func testMissingPath() {
        let urlString = "https://example.com"
        let url = URL(validatedString: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString + "/")
    }
}
