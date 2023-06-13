//
//  Tests_AddressBookService.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 13/4/2023.
//

import XCTest
@testable import Subconscious

final class Tests_AddressBookService: XCTestCase {
    func testFollowUser() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try await addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy")!
        try await addressBook.followUser(did: did, petname: petname)
        
        let newEntries = try await addressBook.listEntries()
        let user = newEntries[0]
        
        XCTAssertEqual(user.did, did)
        XCTAssertEqual(user.petname, petname)
    }
    
    func testUnfollowByPetname() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try await addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy")!
        try await addressBook.followUser(did: did, petname: petname)
        
        let did2 = Did("did:key:456")!
        let petname2 = Petname("flubbo")!
        try await addressBook.followUser(did: did2, petname: petname2)
        
        let newEntries = try await addressBook.listEntries()
        
        XCTAssertEqual(newEntries.count, 2)
        
        try await addressBook.unfollowUser(petname: petname)
        
        let finalEntries = try await addressBook.listEntries()
        let user = finalEntries[0]
        
        XCTAssertEqual(finalEntries.count, 1)
        XCTAssertEqual(user.did, did2)
        XCTAssertEqual(user.petname, petname2)
    }
    
    func testFindAvailablePetname() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try await addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        let did = Did("did:key:123")!
        let petname = Petname.Name("ziggy")!
        try await addressBook.followUser(did: did, petname: petname.toPetname())
        
        let newPetname = try await addressBook.findAvailablePetname(name: petname)
        XCTAssertEqual(newPetname, Petname.Name("ziggy-1")!)
    }
    
    func testFindAvailablePetnameWithExistingSuffix() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try await addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        for i in 0..<64 {
            let did = Did("did:key:123\(i)")!
            let petname = Petname("ziggy-\(i)")!
            try await addressBook.followUser(did: did, petname: petname)
        }
        
        let newPetname = try await addressBook.findAvailablePetname(name: Petname.Name("ziggy-1")!)
        XCTAssertEqual(newPetname, Petname.Name("ziggy-64")!)
    }
    
    func testIsFollowingUserAndHasEntryFor() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        let addressBook = data.addressBook
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy-2")!
        
        let a = await addressBook.followingStatus(did: did)
        let b = await addressBook.hasEntryForPetname(petname: petname)
        XCTAssertFalse(a.isFollowing)
        XCTAssertFalse(b)
    
        try await addressBook.followUser(did: did, petname: petname)
        
        let c = await addressBook.followingStatus(did: did)
        let d = await addressBook.hasEntryForPetname(petname: petname)
        XCTAssertTrue(c.isFollowing)
        XCTAssertTrue(d)
        
        try await addressBook.unfollowUser(petname: petname)
        
        let e = await addressBook.followingStatus(did: did)
        let f = await addressBook.hasEntryForPetname(petname: petname)
        XCTAssertFalse(e.isFollowing)
        XCTAssertFalse(f)
    }
}
