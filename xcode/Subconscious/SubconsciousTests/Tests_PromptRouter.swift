//
//  Tests_PromptRouter.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/7/24.
//

import XCTest
@testable import Subconscious

final class Tests_PromptRouter: XCTestCase {
    func testRecursionSafety() async throws {
        let classifier = PromptClassifier()
        var router = PromptRouter(classifier: classifier)
        // Deliberately infinitely recursive route
        router.route(
            PromptRoute { request in
                await request.process(request.input)
            }
        )
        let result = await router.process("Hello world")
        XCTAssertNil(result, "Recursive routes exit after a certain depth")
    }
}
