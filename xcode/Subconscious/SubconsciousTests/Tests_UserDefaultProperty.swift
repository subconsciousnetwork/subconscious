//
//  Tests_UserDefaultProperty.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/30/23.
//

import XCTest
import Combine
@testable import Subconscious

final class Tests_UserDefaultProperty: XCTestCase {
    struct Defaults {
        static var defaults = UserDefaults()
        
        @UserDefaultsProperty(forKey: "isToggled", scope: Self.defaults)
        var isToggled = true
        
        @UserDefaultsProperty(forKey: "name", scope: Self.defaults)
        var name = ""
    }
    
    var cancellables: Set<AnyCancellable> = Set()

    override func setUp() {
        self.cancellables = Set()
    }

    func testPersists() throws {
        let test = Defaults()
        test.isToggled = false
        let valueFromDefaults = Defaults.defaults
            .value(forKey: "isToggled") as? Bool
        XCTAssertEqual(test.isToggled, valueFromDefaults)
    }
    
    func testProjectedValuePublisherDeduplicates() throws {
        let test = Defaults()
        var count = 0
        test.$isToggled.sink { isToggled in
            count = count + 1
        }
        .store(in: &cancellables)
        test.isToggled = true
        test.isToggled = false
        test.isToggled = false
        test.isToggled = false
        test.isToggled = false
        XCTAssertEqual(count, 2)
    }
}
