//
//  Tests_Redacted.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 9/27/23.
//

import XCTest
@testable import Subconscious

final class Tests_Redacted: XCTestCase {
    struct Person {
        var id: Int
        @Redacted var name: String
        @Redacted var age: Float
    }
    
    func testValue() throws {
        let person = Person(
            id: 1,
            name: "Keyser Soze",
            age: 45
        )
        XCTAssertEqual(
            person.name,
            "Keyser Soze"
        )
        XCTAssertEqual(
            String(describing: person.name),
            "Keyser Soze"
        )
        XCTAssertEqual(
            person.age,
            45
        )
    }
    
    func testStringDescribing() throws {
        let person = Person(
            id: 1,
            name: "Keyser Soze",
            age: 45
        )
        let string = String(describing: person)
        XCTAssertEqual(
            string,
            "Person(id: 1, _name: --redacted--, _age: --redacted--)"
        )
    }
    
    func testStringReflecting() throws {
        let person = Person(
            id: 1,
            name: "Keyser Soze",
            age: 45
        )
        let string = String(reflecting: person)
        XCTAssertFalse(string.contains("Keyser Soze"))
        XCTAssertFalse(string.contains("45"))
    }
}
