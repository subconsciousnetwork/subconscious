//
//  Tests_UserLikesService.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 9/2/2024.
//

import XCTest
@testable import Subconscious

final class Tests_UserLikesService: XCTestCase {
    func testReadLikes() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let likes = try await data.userLikes.readOurLikes()
        
        XCTAssert(likes.isEmpty)
    }
}
