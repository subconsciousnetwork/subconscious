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
        
        AppDefaults.standard.nickname = "test"
        
        let memoA = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "More content"
        )
        
        let addressA = Slashlink(slug: Slug("hello")!).toPublicMemoAddress()
        try await data.data.writeMemo(address: addressA, memo: memoA)
        
        let memoC = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Even more content"
        )
        
        let addressC = Slashlink.ourProfile.toPublicMemoAddress()
        try await data.data.writeMemo(address: addressC, memo: memoC)
        
        try await data.userProfile.writeOurProfile(
            profile: UserProfileEntry(
                nickname: "alice",
                bio: nil,
                profilePictureUrl: nil
            )
        )
        
        let profile = try await data.userProfile.requestOurProfile()
        
        XCTAssertEqual(profile.profile.nickname, Petname("alice")!)
        XCTAssertEqual(profile.entries.count, 1)
        // No hidden entries on profile
        XCTAssertFalse(profile.entries.contains(where: { entry in entry.address.slug.isHidden }))
    }
}
