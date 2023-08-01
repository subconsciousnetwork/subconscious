//
//  Tests_FileFingerprint.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/26/22.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

final class Tests_FileFingerprint: XCTestCase {
    /// Modified time as Unix Timestamp Integer (rounded to the nearest second).
    /// We were previously getting what appeared to be rounding precision errors
    /// when serializing datetimes as ISO strings.
    ///
    /// Additionally, file timestamps precision is limited to:
    /// 1 second for EXT3
    /// 1 microsecond for UFS
    /// 1 nanosecond for EXT4
    ///
    /// To-the-nearest-second precision is fine for the purpose of comparing changes, and
    /// handwaves away these issues.
    ///
    /// 2021-07-26 Gordon Brander
    func testAttributesRoundsModifiedToNearestSecond() throws {
        let now = Date.now
        let nowRoundedToNearestSecond = Int(now.timeIntervalSince1970)
        let attributes = FileFingerprint.Attributes(modified: now, size: 10)
        XCTAssertEqual(
            attributes.modified,
            nowRoundedToNearestSecond,
            "Rounds to nearest second"
        )
    }
}
