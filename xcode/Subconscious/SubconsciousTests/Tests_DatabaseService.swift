//
//  Tests_DatabaseService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/7/22.
//

import XCTest
@testable import Subconscious

class Tests_DatabaseService: XCTestCase {
    func createDatabaseService() throws -> DatabaseService {
        // Setup DB
        let tmp = try TestUtilities.createTmpDir()
        let databaseURL = tmp.appending(
            path: "database.sqlite",
            directoryHint: .notDirectory
        )
        let database = SQLite3Database(
            path: databaseURL.path(percentEncoded: false)
        )
        let service = DatabaseService(
            database: database,
            migrations: Config.migrations
        )
        return service
    }
        
    func testCollateRenameSuggestionsMove() throws {
        let current = Slashlink("/ye-three-unsurrendered-spires-of-mine")!
        let query = Slashlink("/the-whale-the-whale")!
        let results = [
            current,
            Slashlink("/oh-all-ye-sweet-powers-of-air-now-hug-me-close")!,
            Slashlink("/stubbs-own-unwinking-eye")!,
            Slashlink("/pole-pointed-prow")!,
        ]
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: results
        )
        guard case let .move(from, to) = suggestions[0] else {
            let suggestion = String(reflecting: suggestions[0])
            XCTFail(
                "First suggestion expected to be move, but was \(suggestion)"
            )
            return
        }
        XCTAssertEqual(
            from,
            current
        )
        XCTAssertEqual(
            to,
            query
        )
    }
    
    func testCollateRenameSuggestionsMerge() throws {
        let current = Slashlink("/ye-three-unsurrendered-spires-of-mine")!
        let query = Slashlink("/the-whale-the-whale")!
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                Slashlink("/ye-three-unsurrendered-spires-of-mine")!,
                Slashlink("/the-whale-the-whale")!,
                Slashlink("/oh-all-ye-sweet-powers-of-air-now-hug-me-close")!,
                Slashlink("/stubbs-own-unwinking-eye")!,
                Slashlink("/pole-pointed-prow")!,
            ]
        )
        guard case let .merge(parent, child) = suggestions[0] else {
            let suggestion = String(reflecting: suggestions[0])
            XCTFail(
                "First suggestion expected to be merge, but was \(suggestion)"
            )
            return
        }
        XCTAssertEqual(
            parent,
            query
        )
        XCTAssertEqual(
            child,
            current
        )
    }
    
    func testListLocalMemoFingerprints() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()

        // Add some entries to DB
        let now = Date.now
        
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("foo")!
            ),
            memo: foo,
            size: foo.toHeaderSubtext().size()!
        )
        
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("bar")!
            ),
            memo: bar,
            size: bar.toHeaderSubtext().size()!
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        try service.writeMemo(
            link: Link(
                did: Did("did:key:abc123")!,
                slug: Slug("baz")!
            ),
            memo: baz
        )
        
        let fingerprints = try service.listLocalMemoFingerprints()
        XCTAssertEqual(fingerprints.count, 2, "Only selects local memos")
        
        let slugs = Set(
            fingerprints.map({ fingerprint in fingerprint.slug })
        )
        XCTAssertTrue(slugs.contains(Slug("foo")!))
        XCTAssertTrue(slugs.contains(Slug("bar")!))
    }
    
    func testListRecentMemos() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()

        // Add some entries to DB
        let now = Date.now
        
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("foo")!
            ),
            memo: foo,
            size: foo.toHeaderSubtext().size()!
        )
        
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("bar")!
            ),
            memo: bar,
            size: bar.toHeaderSubtext().size()!
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        try service.writeMemo(
            link: Link(
                did: Did("did:key:abc123")!,
                slug: Slug("baz")!
            ),
            memo: baz
        )
        
        let recent = try service.listRecentMemos(owner: Did("did:key:abc123")!)
        
        XCTAssertEqual(recent.count, 3)
        
        let slashlinks = Set(
            recent.compactMap({ stub in
                stub.address
            })
        )
        XCTAssertEqual(slashlinks.count, 3)
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    slug: Slug("baz")!
                )
            )
        )
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(Did.local),
                    slug: Slug("foo")!
                )
            )
        )
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(Did.local),
                    slug: Slug("bar")!
                )
            )
        )
    }
    
    func testListRecentMemosWithoutOwner() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()

        // Add some entries to DB
        let now = Date.now
        
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("foo")!
            ),
            memo: foo,
            size: foo.toHeaderSubtext().size()!
        )
        
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("bar")!
            ),
            memo: bar,
            size: bar.toHeaderSubtext().size()!
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        try service.writeMemo(
            link: Link(
                did: Did("did:key:abc123")!,
                slug: Slug("baz")!
            ),
            memo: baz
        )
        
        let recent = try service.listRecentMemos(owner: nil)
        
        XCTAssertEqual(recent.count, 2)
        
        let slashlinks = Set(
            recent.compactMap({ stub in
                stub.address
            })
        )
        XCTAssertEqual(slashlinks.count, 2)
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(Did.local),
                    slug: Slug("foo")!
                )
            )
        )
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(Did.local),
                    slug: Slug("bar")!
                )
            )
        )
    }
    
    func testSearchSuggestions() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()

        // Add some entries to DB
        let now = Date.now
        
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("foo")!
            ),
            memo: foo,
            size: foo.toHeaderSubtext().size()!
        )
        
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("bar")!
            ),
            memo: bar,
            size: bar.toHeaderSubtext().size()!
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        try service.writeMemo(
            link: Link(
                did: Did("did:key:abc123")!,
                slug: Slug("baz")!
            ),
            memo: baz
        )
        
        let results = try service.searchSuggestions(
            owner: Did("did:key:abc123")!,
            query: "baz"
        )
        let slashlink = results
            .compactMap({ result in
                switch result {
                case let .memo(address, _):
                    return address
                default:
                    return nil
                }
            })
            .first
        XCTAssertEqual(
            slashlink,
            Slashlink("/baz")!,
            "When owner is present, slashlink is relativized"
        )
    }
    
    func testSearchSuggestionsWithoutOwner() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()

        // Add some entries to DB
        let now = Date.now
        
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("foo")!
            ),
            memo: foo,
            size: foo.toHeaderSubtext().size()!
        )
        
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            link: Link(
                did: Did.local,
                slug: Slug("bar")!
            ),
            memo: bar,
            size: bar.toHeaderSubtext().size()!
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        try service.writeMemo(
            link: Link(
                did: Did("did:key:abc123")!,
                slug: Slug("baz")!
            ),
            memo: baz
        )
        
        let results = try service.searchSuggestions(
            owner: nil,
            query: "baz"
        )
        let slashlink = results
            .compactMap({ result in
                switch result {
                case let .memo(address, _):
                    return address
                default:
                    return nil
                }
            })
            .first
        XCTAssertEqual(
            slashlink,
            Slashlink(
                peer: Peer.did(Did("did:key:abc123")!),
                slug: Slug("baz")!
            ),
            "When owner is not present, slashlink is not relativized"
        )
    }
}
