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
    
    func testReadLikesAfterWriting() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let likes = try await data.userLikes.readOurLikes()
        
        XCTAssert(likes.isEmpty)
        
        try await data.userLikes.persistLike(for: Slashlink("@ben/test")!)
        
        let likes2 = try await data.userLikes.readOurLikes()
        
        XCTAssert(likes2.count == 1)
    }
    
    func testRemoveLike() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let likes = try await data.userLikes.readOurLikes()
        
        XCTAssert(likes.isEmpty)
        
        try await data.userLikes.persistLike(for: Slashlink("@ben/test")!)
        try await data.userLikes.persistLike(for: Slashlink("@ben/lmao")!)
        try await data.userLikes.persistLike(for: Slashlink("@ben/lmao")!)
        
        let likes2 = try await data.userLikes.readOurLikes()
        
        XCTAssert(likes2.count == 3)
        
        try await data.userLikes.removeLike(for: Slashlink("@ben/lmao")!)
        
        let likes3 = try await data.userLikes.readOurLikes()
        
        XCTAssert(likes3.count == 1)
    }
    
    func testIsLiked() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let likes = try await data.userLikes.readOurLikes()
        
        XCTAssert(likes.isEmpty)
        
        try await data.userLikes.persistLike(for: Slashlink("@ben/test")!)
        try await data.userLikes.persistLike(for: Slashlink("@ben/lmao")!)
        try await data.userLikes.persistLike(for: Slashlink("@ben/lmao")!)
        
        let liked = try await data.userLikes.isLikedByUs(address: Slashlink("@ben/lmao")!)
        
        XCTAssertTrue(liked)
    }
}
