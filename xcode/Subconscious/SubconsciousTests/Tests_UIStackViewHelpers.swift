//
//  Tests_UIStackViewHelpers.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 8/31/23.
//

import XCTest
import UIKit
@testable import Subconscious

final class Tests_UIStackViewHelpers: XCTestCase {
    func testRemoveAllArrangedSubviews() throws {
        let stackView = UIStackView()
        let a = UIView()
        let b = UIView()
        let c = UIView()
        
        stackView.addArrangedSubview(a)
        stackView.addArrangedSubview(b)
        stackView.addArrangedSubview(c)

        // Sanity check
        XCTAssertEqual(stackView.arrangedSubviews.count, 3)

        stackView.removeAllArrangedSubviews()
        
        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }
}
