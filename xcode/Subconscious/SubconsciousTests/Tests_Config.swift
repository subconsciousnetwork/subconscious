//
//  Tests_Config.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 21/7/2023.
//

import XCTest
@testable import Subconscious

final class Tests_Config: XCTestCase {
    func testLoadBuildVars() throws {
        let _debug = Config.default.debug
        let _defaultGeistDid = Config.default.subconsciousGeistDid
        let _defaultGeistPetname = Config.default.subconsciousGeistPetname
        let _feedbackUrl = Config.default.feedbackURL
        let _cloudCtlUrl = Config.default.cloudCtlUrl
    }
}
    
