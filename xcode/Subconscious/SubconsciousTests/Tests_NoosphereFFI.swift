//
//  Tests_NoosphereFFI.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/2/23.
//

import XCTest
import Noosphere
@testable import Subconscious

final class Tests_NoosphereFFI: XCTestCase {
    func testCallWithError() throws {
        let noosphere = ns_initialize("/tmp/foo", "/tmp/bar", nil, nil)
        defer {
            ns_free(noosphere)
        }

        let bad_sphere_identity = "doesnotexist"
        
        XCTAssertThrowsError(
            try NoosphereFFI.callWithError(
                ns_sphere_fs_open,
                noosphere,
                bad_sphere_identity
            )
        )
    }
}
