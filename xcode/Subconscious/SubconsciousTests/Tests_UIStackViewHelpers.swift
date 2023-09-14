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
    func testRemoveArrangedSubviewCompletely() throws {
        let stackView = UIStackView()
        let a = UIView()
        let b = UIView()
        let c = UIView()
        
        stackView.addArrangedSubview(a)
        stackView.addArrangedSubview(b)
        stackView.addArrangedSubview(c)

        // Sanity check
        XCTAssertEqual(stackView.arrangedSubviews.count, 3)
        XCTAssertEqual(stackView.subviews.count, 3)

        stackView.removeArrangedSubviewCompletely(view: a)

        XCTAssertEqual(stackView.arrangedSubviews.count, 2)
        XCTAssertEqual(stackView.subviews.count, 2)
        
        XCTAssertFalse(
            stackView.arrangedSubviews.contains(
                where: { view in
                    view === a
                }
            ),
            "Removes from arranged subviews"
        )

        XCTAssertFalse(
            stackView.subviews.contains(
                where: { view in
                    view === a
                }
            ),
            "Removes from subviews"
        )
    }

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

        stackView.removeAllArrangedSubviewsCompletely()
        
        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }
}
