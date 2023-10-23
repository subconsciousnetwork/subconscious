//
//  Tests_UserProfileService.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 26/4/2023.
//

import XCTest
@testable import Subconscious

final class Tests_UserProfileService: XCTestCase {
    func testAliases() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let receiptA = try await data.noosphere.createSphere(ownerKeyName: "foo")
        let receiptB = try await data.noosphere.createSphere(ownerKeyName: "bar")
        let didA = Did(receiptA.identity)!
        let didB = Did(receiptB.identity)!
        
        await data.noosphere.resetSphere(didA.did)
        
        try await data.addressBook.followUser(did: didB, petname: Petname("sphere-b")!)
        try await data.addressBook.followUser(did: didB, petname: Petname("sphere-b-again")!)
        
        let profile = try await data.userProfile.loadOurFullProfileData()
        
        XCTAssertEqual(profile.following.count, 2)
        for entry in profile.following {
            XCTAssertEqual(entry.user.did, didB)
        }
        
        XCTAssertEqual(profile.following[0].user.address, Slashlink(petname: Petname("sphere-b")!))
        XCTAssertTrue(profile.following[0].user.aliases.contains(where: { name in name == Petname("sphere-b-again")! }))
        XCTAssertEqual(profile.following[1].user.address, Slashlink(petname: Petname("sphere-b-again")!))
        XCTAssertTrue(profile.following[1].user.aliases.contains(where: { name in name == Petname("sphere-b")! }))
    }
    
    func testIdentifyUserRebaseOnContext() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let createPeerSphere = {
            let receipt = try await environment.noosphere.createSphere(ownerKeyName: "test")
            let did = Did(receipt.identity)!
            
            await environment.noosphere.resetSphere(receipt.identity)
            
            try await environment.userProfile.writeOurProfile(
                profile: UserProfileEntry(
                    nickname: "Finn",
                    bio: "Mathematical!"
                )
            )
            
            return did
        }
        // In a closure to avoid polluting lexical scope
        let peerDid = try await createPeerSphere()
        
        let receipt = try await environment.noosphere.createSphere(ownerKeyName: "test")
        let ourDid = Did(receipt.identity)!
        
        await environment.noosphere.resetSphere(receipt.identity)
        
        try await environment.userProfile.writeOurProfile(
            profile: UserProfileEntry(
                nickname: "Jake",
                bio: "Bacon pancakes!"
            )
        )
        
        try await environment.addressBook.followUser(did: peerDid, petname: Petname("finn-the-human")!)
        
        let _ = try await environment.data.indexOurSphere()
        
        let ourProfile = try await environment.userProfile.identifyUser(
            did: ourDid,
            address: Slashlink(petname: Petname("more.path")!),
            context: Petname("some.long.path")!
        )
        
        // Our profile should use the shortest path
        XCTAssertEqual(ourProfile.did, ourDid)
        XCTAssertEqual(ourProfile.address, Slashlink.ourProfile)
        
        // Deliberately give this user a different address to our known name for them
        let profile = try await environment.userProfile.identifyUser(
            did: peerDid,
            address: Slashlink(petname: Petname("more.path")!),
            context: Petname("some.long.path")!
        )
        
        // Someone we know SHOULD be rebased
        XCTAssertEqual(profile.did, peerDid)
        XCTAssertEqual(profile.address, Slashlink(petname: Petname("more.path.some.long.path")!))
        XCTAssertEqual(profile.aliases.count, 2)
        XCTAssertTrue(profile.aliases.contains(where: { petname in petname == Petname("finn-the-human")! }))
        XCTAssertTrue(profile.aliases.contains(where: { petname in petname == Petname("more.path") }))
    }
    
    func testIdentifyUserCallSignatures() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let receipt = try await environment.noosphere.createSphere(ownerKeyName: "test")
        let did = Did(receipt.identity)!
        
        await environment.noosphere.resetSphere(receipt.identity)
        
        try await environment.userProfile.writeOurProfile(
            profile: UserProfileEntry(
                nickname: "Finn",
                bio: "Mathematical!"
            )
        )
        
        let _ = try await environment.data.indexOurSphere()
        
        let profileA = try await environment.userProfile.identifyUser(
            did: did,
            address: Slashlink.ourProfile,
            context: .none
        )
        
        let profileB = try await environment.userProfile.identifyUser(
            did: did,
            petname: nil,
            context: .none
        )
        
        let profileC = try await environment.userProfile.identifyUser(
            entry: AddressBookEntry(
                petname: Petname("ourselves")!,
                did: did,
                status: .resolved(Cid("ok")),
                version: Cid("ok")
            ),
            context: .none
        )
        
        XCTAssertEqual(profileB.did, did)
        XCTAssertEqual(profileC.did, did)
        
        let profiles = [profileA, profileB, profileC]
        for profile in profiles {
            XCTAssertEqual(profile.did, did)
            XCTAssertTrue(profile.address.isOurProfile)
            XCTAssertEqual(profile.ourFollowStatus, .notFollowing)
            XCTAssertEqual(profile.category, .ourself)
            XCTAssertEqual(profile.bio?.text.description, "Mathematical!")
            XCTAssertEqual(profile.nickname?.description, "finn")
        }
    }
    
    func testReadUserProfile() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let receipt = try await environment.noosphere.createSphere(ownerKeyName: "test")
        let did = Did(receipt.identity)!
        
        await environment.noosphere.resetSphere(receipt.identity)
        
        try await environment.userProfile.writeOurProfile(
            profile: UserProfileEntry(
                nickname: "Finn",
                bio: "Mathematical!"
            )
        )
        
        let _ = try await environment.data.indexOurSphere()
        
        let profileA = try await environment.userProfile.readProfileFromDb(did: did)
        let profileB = await environment.userProfile.readProfileMemo(sphere: environment.noosphere)
        
        XCTAssertEqual(profileA, profileB)
    }
    
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
                bio: "my bio"
            )
        )
        
        let _ = try await data.addressBook.followUser(
            did: Did("did:key:123")!,
            petname: Petname("ronald")!
        )
        
        let profile = try await data.userProfile.loadOurFullProfileData()
        
        XCTAssertEqual(profile.profile.nickname, Petname.Name("alice")!)
        XCTAssertEqual(profile.profile.bio, UserProfileBio("my bio"))
        XCTAssertEqual(profile.recentEntries.count, 1)
        // No hidden entries on profile
        XCTAssertFalse(profile.recentEntries.contains(where: { entry in entry.address.slug.isHidden }))
        
        XCTAssertEqual(profile.following.count, 1)
        if let petname = profile.following.first?.user.address.petname {
            XCTAssertEqual(petname, Petname("ronald"))
        }
    }
}
