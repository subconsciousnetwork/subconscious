//
//  Tests_TranscludeService.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 26/6/2023.
//

import XCTest
import Combine
import ObservableStore
@testable import Subconscious

final class Tests_TranscludeService: XCTestCase {
    /// A place to put cancellables from publishers
    var cancellables: Set<AnyCancellable> = Set()
    
    var data: DataService?
    
    func testOurAddressComposition() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let base = Slashlink(slug: Slug("note")!)
        let link = Slashlink(petname: Petname("hello")!, slug: Slug("ok")!)
        
        let combined = await environment
            .transclude
            .combineAddresses(base: base, link: link)
        
        XCTAssertEqual(combined, Slashlink(petname: Petname("hello")!, slug: Slug("ok")!))
    }
    
    
    func testRelativeAddressComposition() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let base = Slashlink(petname: Petname("ben.gordon")!, slug: Slug("note")!)
        let link = Slashlink(slug: Slug("ok")!)
        
        let combined = await environment
            .transclude
            .combineAddresses(base: base, link: link)
        
        XCTAssertEqual(combined, Slashlink(petname: Petname("ben.gordon")!, slug: Slug("ok")!))
    }
    
    func testComplexAddressComposition() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let base = Slashlink(petname: Petname("ben.gordon")!, slug: Slug("note")!)
        let link = Slashlink(petname: Petname("jordan.chris"), slug: Slug("ok")!)
        
        let combined = await environment
            .transclude
            .combineAddresses(base: base, link: link)
        
        XCTAssertEqual(combined, Slashlink(petname: Petname("jordan.chris.ben.gordon")!, slug: Slug("ok")!))
    }
    
    func testResolveToOurDid() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let base = Slashlink(slug: Slug("note")!)
        let link = Slashlink(slug: Slug("ok")!)
        
        let newLink = try await environment
            .transclude
            .resolveAddresses(base: base, link: link)
        
        let identity = try await environment.noosphere.identity()
        let did = newLink.address.toDid()!
        XCTAssertEqual(did, identity)
        XCTAssertEqual(newLink.address.slug, link.slug)
    }
    
    func testResolveToKnownDid() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let sarah = Did.dummyData()
        try await environment.noosphere.setPetname(did: sarah, petname: Petname("sarah")!)
        try await environment.noosphere.save()
        
        let base = Slashlink(slug: Slug("note")!)
        let link = Slashlink(petname: Petname("sarah")!, slug: Slug("ok")!)
        
        let newLink = try await environment
            .transclude
            .resolveAddresses(base: base, link: link)
        
        let did = newLink.address.toDid()!
        XCTAssertEqual(did, sarah)
        XCTAssertEqual(newLink.address.slug, link.slug)
    }
    
    func testFetchLocalTranscludes() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let address = Slashlink("/test")!
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try await environment.data.writeMemo(
            address: address,
            memo: memo
        )
        
        let address2 = Slashlink("/test-again")!
        let memo2 = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "With different content"
        )
        
        try await environment.data.writeMemo(
            address: address2,
            memo: memo2
        )
        
        _ = try await environment.data.indexOurSphere()
        
        let profile = UserProfile.dummyData(category: .ourself)
        
        let transcludes = try await environment
            .transclude
            .fetchTranscludePreviews(
                slashlinks: [address, address2],
                owner: profile
            )
        
        XCTAssertEqual(transcludes.count, 2)
        XCTAssertTrue(transcludes[address] != nil)
        XCTAssertEqual(transcludes[address]!.excerpt, "Test content")
        XCTAssertTrue(transcludes[address2] != nil)
        XCTAssertEqual(transcludes[address2]!.excerpt, "With different content")
    }
}
