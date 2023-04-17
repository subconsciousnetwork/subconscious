//
//  Tests_Func.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/14/23.
//

import XCTest
@testable import Subconscious

final class Tests_Func: XCTestCase {
    func testPipe() throws {
        let x = Func.pipe(2, through: { x in x * x })
        XCTAssertEqual(x, 4)
    }
    
    func testRun() throws {
        let x = Func.run({ 15 })
        XCTAssertEqual(x, 15, "Returns value")
    }
    
    func testRunAsync() async throws {
        let x = try await Func.run({
            try await Task.sleep(for: .seconds(0.1))
            return 15
        })
        XCTAssertEqual(x, 15, "Returns value")
    }

    enum TestError: Error {
        case error
    }

    func testRunThrows() throws {
        XCTAssertThrowsError(
            try Func.run({
                throw TestError.error
            }),
            "Propagates error"
        )
    }
}
