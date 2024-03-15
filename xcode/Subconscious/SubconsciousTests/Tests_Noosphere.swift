//
//  Tests_NoosphereFFI.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/2/23.
//

import XCTest
import Noosphere
@testable import Subconscious

final class Tests_Noosphere: XCTestCase {
    @NoosphereActor
    func testCallWithError() throws {
        let noosphere = ns_initialize("/tmp/foo", "/tmp/bar", nil, nil)
        defer {
            ns_free(noosphere)
        }
        
        let bad_sphere_identity = "doesnotexist"
        
        XCTAssertThrowsError(
            try Noosphere.callWithError(
                ns_sphere_open,
                noosphere,
                bad_sphere_identity
            )
        )
    }
    
    func testNoosphereLogLevel() throws {
        XCTAssertEqual(
            Noosphere.NoosphereLogLevel.academic.rawValue,
            NS_NOOSPHERE_LOG_ACADEMIC.rawValue
        )
        XCTAssertEqual(
            Noosphere.NoosphereLogLevel.basic.rawValue,
            NS_NOOSPHERE_LOG_BASIC.rawValue
        )
        XCTAssertEqual(
            Noosphere.NoosphereLogLevel.chatty.rawValue,
            NS_NOOSPHERE_LOG_CHATTY.rawValue
        )
        XCTAssertEqual(
            Noosphere.NoosphereLogLevel.deafening.rawValue,
            NS_NOOSPHERE_LOG_DEAFENING.rawValue
        )
        XCTAssertEqual(
            Noosphere.NoosphereLogLevel.informed.rawValue,
            NS_NOOSPHERE_LOG_INFORMED.rawValue
        )
        XCTAssertEqual(
            Noosphere.NoosphereLogLevel.silent.rawValue,
            NS_NOOSPHERE_LOG_SILENT.rawValue
        )
        XCTAssertEqual(
            Noosphere.NoosphereLogLevel.tiresome.rawValue,
            NS_NOOSPHERE_LOG_TIRESOME.rawValue
        )
    }
}
