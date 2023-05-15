//
//  Tests_UserProfileService.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 26/4/2023.
//

import XCTest
@testable import Subconscious

final class Tests_UserProfileService: XCTestCase {
    func testCanRequestOwnProfile() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let memoA = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "More content"
        )
        
        let addressA = Slashlink(slug: Slug("hello")!)
        try await data.data.writeMemo(address: addressA, memo: memoA)
        
        let memoC = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Even more content"
        )
        
        let addressC = Slashlink.ourProfile
        try await data.data.writeMemo(address: addressC, memo: memoC)
        
        try await data.userProfile.writeOurProfile(
            profile: UserProfileEntry(
                nickname: "alice",
                bio: nil,
                profilePictureUrl: nil
            )
        )
        
        let _ = try await data.addressBook.followUser(did: Did("did:key:123")!, petname: Petname("ronald")!)
        
        let profile = try await data.userProfile.requestOurProfile()
        
        XCTAssertEqual(profile.profile.nickname, Petname("alice")!)
        XCTAssertEqual(profile.recentEntries.count, 1)
        // No hidden entries on profile
        XCTAssertFalse(profile.recentEntries.contains(where: { entry in entry.address.slug.isHidden }))
        
        XCTAssertEqual(profile.following.count, 1)
        if let petname = profile.following.first?.user.address.petname {
            XCTAssertEqual(petname, Petname("ronald"))
        }
    }
    
    func testFollowingListAddresses() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let _ = try await data.addressBook.followUser(
            did: Did("did:key:123")!,
            petname: Petname("ronald")!
        )
        
        let following = try await data.userProfile.getFollowingList(
            address: Slashlink.ourProfile
        )
        
        if let petname = following.first?.user.address.petname {
            XCTAssertEqual(petname, Petname("ronald")!)
        } else {
            XCTFail("No followed users")
        }
    }
}
