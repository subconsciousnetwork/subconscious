//
//  Tests_URLUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/22/23.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

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
        let url = URL(validating: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }
    
    func testPreservesUrlComponents() {
        let urlString = "https://example.com:8080/image.jpg?q=123#hello"
        let url = URL(validating: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }
    
    func testSchemeOnly() {
        let a = URL(validating: "http:")
        XCTAssertNil(a)
        
        let b = URL(validating: "https:")
        XCTAssertNil(b)
    }
    
    func testInvalidURL() {
        let urlString = "not a url"
        let url = URL(validating: urlString)
        XCTAssertNil(url)
    }
    
    func testInvalidScheme() {
        let urlString = "ftp://example.com/image.jpg"
        let url = URL(validating: urlString)
        XCTAssertNil(url)
    }
    
    func testMissingHost() {
        let urlString = "https:///image.jpg"
        let url = URL(validating: urlString)
        XCTAssertNil(url)
    }
    
    func testMissingPath() {
        let urlString = "https://example.com"
        let url = URL(validating: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }
    
    func testPort() {
        let urlString = "https://example.com:8080"
        let url = URL(validating: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }
    
    func testIpAddress() {
        let urlString = "https://127.0.0.1"
        let url = URL(validating: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }
}
