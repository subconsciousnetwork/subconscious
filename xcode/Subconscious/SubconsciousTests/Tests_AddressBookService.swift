//
//  Tests_AddressBookService.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 13/4/2023.
//

import XCTest
@testable import Subconscious

final class Tests_AddressBookService: XCTestCase {
    func testFollowUser() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy")!
        try addressBook.followUser(did: did, petname: petname)
        
        let newEntries = try addressBook.listEntries()
        let user = newEntries[0]
        
        XCTAssertEqual(user.did, did)
        XCTAssertEqual(user.petname, petname)
    }
    
    func testUnfollowByPetname() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy")!
        try addressBook.followUser(did: did, petname: petname)
        
        let did2 = Did("did:key:456")!
        let petname2 = Petname("flubbo")!
        try addressBook.followUser(did: did2, petname: petname2)
        
        let newEntries = try addressBook.listEntries()
        
        XCTAssertEqual(newEntries.count, 2)
        
        try addressBook.unfollowUser(petname: petname)
        
        let finalEntries = try addressBook.listEntries()
        let user = finalEntries[0]
        
        XCTAssertEqual(finalEntries.count, 1)
        XCTAssertEqual(user.did, did2)
        XCTAssertEqual(user.petname, petname2)
    }
    
    func testUnfollowByDid() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy")!
        try addressBook.followUser(did: did, petname: petname)
        
        let did2 = Did("did:key:456")!
        let petname2 = Petname("flubbo")!
        try addressBook.followUser(did: did2, petname: petname2)
        
        let newEntries = try addressBook.listEntries()
        
        XCTAssertEqual(newEntries.count, 2)
        
        try addressBook.unfollowUser(did: did)
        
        let finalEntries = try addressBook.listEntries()
        let user = finalEntries[0]
        
        XCTAssertEqual(finalEntries.count, 1)
        XCTAssertEqual(user.did, did2)
        XCTAssertEqual(user.petname, petname2)
    }
    
    func testFindAvailablePetname() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy")!
        try addressBook.followUser(did: did, petname: petname)
        
        let newPetname = try addressBook.findAvailablePetname(petname: Petname("ziggy")!)
        XCTAssertEqual(newPetname, Petname("ziggy-1")!)
    }
    
    func testFindAvailablePetnameWithExistingSuffix() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        let addressBook = data.addressBook
        
        let entries = try addressBook.listEntries()
        XCTAssertEqual(entries, [])
        
        for i in 0..<64 {
            let did = Did("did:key:123\(i)")!
            let petname = Petname("ziggy-\(i)")!
            try addressBook.followUser(did: did, petname: petname)
        }
        
        let newPetname = try addressBook.findAvailablePetname(petname: Petname("ziggy-1")!)
        XCTAssertEqual(newPetname, Petname("ziggy-64")!)
    }
    
    func testIsFollowingUser() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        let addressBook = data.addressBook
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy-2")!
        
        let a = try addressBook.isFollowingUser(did: did)
        let b = addressBook.isFollowingUser(did: did, petname: petname)
        XCTAssertFalse(a)
        XCTAssertFalse(b)
    
        try addressBook.followUser(did: did, petname: petname)
        
        let c = try addressBook.isFollowingUser(did: did)
        let d = addressBook.isFollowingUser(did: did, petname: petname)
        XCTAssertTrue(c)
        XCTAssertTrue(d)
        
        try addressBook.unfollowUser(did: did)
        
        let e = try addressBook.isFollowingUser(did: did)
        let f = addressBook.isFollowingUser(did: did, petname: petname)
        XCTAssertFalse(e)
        XCTAssertFalse(f)
    }
    
    func testHasEntryFor() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        let addressBook = data.addressBook
        
        let did = Did("did:key:123")!
        let petname = Petname("ziggy-2")!
        
        XCTAssertFalse(addressBook.hasEntryForPetname(petname: petname))
        
        try addressBook.followUser(did: did, petname: petname)
        
        XCTAssertTrue(addressBook.hasEntryForPetname(petname: petname))
        
        try addressBook.unfollowUser(did: did)
        
        XCTAssertFalse(addressBook.hasEntryForPetname(petname: petname))
    }
}
