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
    
    func testResolveToOurDid() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let link = Slashlink(slug: Slug("ok")!)
        
        let newLink = try await environment
            .transclude
            .resolveAddresses(base: nil, link: link)
        
        let identity = try await environment.noosphere.identity()
        XCTAssertEqual(newLink.authorDid, identity)
        XCTAssertEqual(newLink.displayAddress.slug, link.slug)
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
        
        let link = Slashlink(petname: Petname("sarah")!, slug: Slug("ok")!)
        
        let newLink = try await environment
            .transclude
            .resolveAddresses(base: nil, link: link)
        
        XCTAssertEqual(newLink.authorDid, sarah)
        XCTAssertEqual(newLink.displayAddress.slug, link.slug)
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
