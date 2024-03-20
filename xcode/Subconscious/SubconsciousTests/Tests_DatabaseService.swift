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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        let did = Did("did:key:abc123")!
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
        )
        
        let recent = try service.listRecentMemos(owner: did, includeDrafts: true)
        
        XCTAssertEqual(recent.count, 3)
        
        XCTAssertEqual(recent[0].did, Did.local)
        XCTAssertEqual(recent[1].did, Did.local)
        XCTAssertEqual(recent[2].did, did)
        
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
    
    func testListAllMemos() throws {
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
        )
        
        
        let did = Did("did:key:abc123")!
        let did2 = Did("did:key:def456")!
        try service.writePeer(PeerRecord(petname: Petname("abc")!, identity: did))
        
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("bar")!,
                memo: bar
            )
        )
        
        let qux = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Qux"
        )
        try service.writeMemo(
            MemoRecord(
                did: did2,
                petname: nil,
                slug: Slug("qux")!,
                memo: qux,
                size: qux.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("baz")!,
                memo: baz,
                size: baz.toHeaderSubtext().size()!
            )
        )

        let recent = try service.listAll(owner: did, limit: 3)
        
        XCTAssertEqual(recent.count, 3)
        
        XCTAssertEqual(recent[0].did, Did.local)
        XCTAssertEqual(recent[1].did, did)
        XCTAssertEqual(recent[2].did, did2)
        
        let slashlinks = Set(
            recent.compactMap({ stub in
                stub.address
            })
        )
        XCTAssertEqual(slashlinks.count, 3)
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(did2),
                    slug: Slug("qux")!
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
                    petname: Petname("abc")!,
                    slug: Slug("bar")!
                )
            )
        )
    }
    
    func testListUnseen() throws {
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
        )
        
        
        let did = Did("did:key:abc123")!
        let did2 = Did("did:key:def456")!
        try service.writePeer(PeerRecord(petname: Petname("abc")!, identity: did))
        
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("bar")!,
                memo: bar
            )
        )
        
        let qux = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Qux"
        )
        try service.writeMemo(
            MemoRecord(
                did: did2,
                petname: nil,
                slug: Slug("qux")!,
                memo: qux,
                size: qux.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("baz")!,
                memo: baz,
                size: baz.toHeaderSubtext().size()!
            )
        )

        let recent = service.readRandomUnseenEntry(
            owner: did,
            seen: [
                Slashlink(
                    slug: Slug("baz")!
                ),
                Slashlink(
                   slug: Slug("foo")!
                ),
                Slashlink(
                    petname: Petname("abc")!,
                    slug: Slug("foo")!
                )
            ]
        )
        
        XCTAssert(recent?.address.slug == Slug("qux"))
    }
    
    func testReadRandomEntryInDateRange() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        // Add some entries to DB
        let now = Date.now
        
        let foo = Memo(
            contentType: "text/subtext",
            created: Date.distantPast,
            modified: Date.distantPast,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
        )
        
        let bar = Memo(
            contentType: "text/subtext",
            created: Date.distantFuture,
            modified: Date.distantFuture,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        let did = Did("did:key:abc123")!
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
        )
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
        
        guard let random = service.readRandomEntryInDateRange(startDate: yesterday, endDate: tomorrow, owner: did) else {
            XCTFail("No entry found")
            return
        }
        
        XCTAssertEqual(random.did, did)
        XCTAssertEqual(random.address.slug, Slug("baz")!)
        XCTAssertEqual(random.address, Slashlink(slug: Slug("baz")!))
    }
    
    func testReadRandomEntryMatching() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        // Add some entries to DB
        let now = Date.now
        
        let foo = Memo(
            contentType: "text/subtext",
            created: Date.distantPast,
            modified: Date.distantPast,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
        )
        
        let bar = Memo(
            contentType: "text/subtext",
            created: Date.distantFuture,
            modified: Date.distantFuture,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
        )
        
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz"
        )
        let did = Did("did:key:abc123")!
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
        )
        
        guard let random = service.readRandomEntryMatching(query: "Foo", owner: did) else {
            XCTFail("No entry found")
            return
        }
        
        XCTAssertEqual(random.did, Did.local)
        XCTAssertEqual(random.address.slug, Slug("foo")!)
        XCTAssertEqual(random.address, Slashlink(peer: .did(Did.local), slug: Slug("foo")!))
        
        let nonExistent = service.readRandomEntryMatching(query: "Baboons", owner: did)
        XCTAssertNil(nonExistent)
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
        )
        
        
        let recent = try service.listRecentMemos(owner: nil, includeDrafts: true)
        
        XCTAssertEqual(recent.count, 2)
        
        XCTAssertEqual(recent[0].did, Did.local)
        XCTAssertEqual(recent[1].did, Did.local)
        
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: nil,
                slug: Slug("baz")!,
                memo: baz
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo,
                size: foo.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
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
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
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
    
    func testSearchSuggestionsFilterHiddenFiles() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        // Add some entries to DB
        let now = Date.now
        
        let did = Did("did:key:abc123")!

        let profile = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo profile"
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: nil,
                slug: Slug.profile,
                memo: profile
            )
        )
        
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: nil,
                slug: Slug("foo")!,
                memo: foo
            )
        )

        let results = try service.searchSuggestions(
            owner: did,
            query: "foo"
        )
        let slugs = results.compactMap({ result in
            switch result {
            case let .memo(address, _):
                return address.slug
            default:
                return nil
            }
        })
        
        XCTAssertFalse(
            slugs.contains(Slug.profile),
            "Hidden file is not part of results"
        )
        XCTAssertEqual(slugs.count, 1, "Hidden file is not returned")
    }
    
    func testReadBodyLinks() throws {
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
            body: "Foo /bar /baz"
        )
        let record = try MemoRecord(
            did: Did("did:key:abc123")!,
            petname: Petname("abc")!,
            slug: Slug("foo")!,
            memo: foo
        )
        try service.writeMemo(record)
        
        // Contains link, should show up in results
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar /foo should appear in results"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
        )
        
        // Contains link, should show up in results
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz /foo should appear in results"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
        )
        
        // Does not contain link, should not show up in results
        let bing = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bing"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("bing")!,
                memo: bing
            )
        )
        
        // Hidden, should not show up in results
        let hidden = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bing"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug(hidden: "hidden")!,
                memo: hidden
            )
        )

        let stubs = try service.readEntryBodyLinks(
            owner: Did("did:key:abc123")!,
            did: Did("did:key:abc123")!,
            slug: Slug("foo")!
        )
        
        let slashlinks = Set(
            stubs.map({ stub in stub.address })
        )
        
        XCTAssertEqual(slashlinks.count, 2)
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(Did.local),
                    slug: Slug("bar")!
                )
            ),
            "Has link, appears in results"
        )
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    slug: Slug("baz")!
                )
            ),
            "Has link, appears in results, with slashlink correctly relativized"
        )
    }

    func testReadBacklinks() throws {
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
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("foo")!,
                memo: foo
            )
        )
        
        // Contains link, should show up in results
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar /foo should appear in results"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
        )
        
        // Contains link, should show up in results
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz /foo should appear in results"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
        )
        
        // Does not contain link, should not show up in results
        let bing = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bing"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("bing")!,
                memo: bing
            )
        )
        
        // Hidden, should not show up in results
        let hidden = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bing"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug(hidden: "hidden")!,
                memo: hidden
            )
        )

        let stubs = try service.readEntryBacklinks(
            owner: Did("did:key:abc123")!,
            did: Did("did:key:abc123")!,
            slug: Slug("foo")!
        )
        
        let slashlinks = Set(
            stubs.map({ stub in stub.address })
        )
        
        XCTAssertEqual(slashlinks.count, 2)
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(Did.local),
                    slug: Slug("bar")!
                )
            ),
            "Has link, appears in results"
        )
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    slug: Slug("baz")!
                )
            ),
            "Has link, appears in results, with slashlink correctly relativized"
        )
    }
    
    func testReadBacklinksWithoutOwner() throws {
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
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("foo")!,
                memo: foo
            )
        )
        
        // Contains link, should show up in results
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar /foo should appear in results"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did("did:key:abc123")!,
                petname: Petname("abc")!,
                slug: Slug("bar")!,
                memo: bar
            )
        )
        
        let stubs = try service.readEntryBacklinks(
            owner: nil,
            did: Did("did:key:abc123")!,
            slug: Slug("foo")!
        )
        
        let slashlinks = Set(
            stubs.map({ stub in stub.address })
        )
        
        XCTAssertEqual(slashlinks.count, 1)
        XCTAssertTrue(
            slashlinks.contains(
                Slashlink(
                    peer: Peer.did(Did("did:key:abc123")!),
                    slug: Slug("bar")!
                )
            ),
            "Has link, appears in results"
        )
    }
    
    func testReadWriteSyncInfoDid() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        let source = PeerRecord(
            petname: Petname("alice")!,
            identity: Did("did:key:abc123")!,
            since: "bafyfakefakefake"
        )
        
        // Write
        try service.writePeer(source)

        let out = try service.readPeer(identity: source.identity)
        
        XCTAssertEqual(out, source)
    }
    
    func testReadWriteSyncInfoPetname() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        let petname = Petname("alice")!
        let source = PeerRecord(
            petname: petname,
            identity: Did("did:key:abc123")!,
            since: "bafyfakefakefake"
        )
        
        // Write
        try service.writePeer(source)

        let out = try service.readPeer(petname: petname)
        
        XCTAssertEqual(out, source)
    }

    func testPurgeSphere() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        // Add some entries to DB
        let now = Date.now
        
        let did = Did("did:key:abc123")!
        
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo"
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("foo")!,
                memo: foo
            )
        )
        
        // Contains link, should show up in results
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar /foo should appear in results"
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
        )
        
        // Contains link, should show up in results
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Baz /foo should appear in results"
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("baz")!,
                memo: baz
            )
        )
        
        // Does not contain link, should not show up in results
        let bing = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bing"
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("bing")!,
                memo: bing
            )
        )
        
        let alice = Petname("alice")!
        let version = "bafyxyz123"
        
        // Write fake sphere sync info so we can purge it
        try service.writePeer(
            PeerRecord(
                petname: alice,
                identity: did,
                since: version
            )
        )
        
        let peer = try service.readPeer(petname: alice)
        XCTAssertNotNil(peer)
        XCTAssertEqual(peer?.identity, did)
        XCTAssertEqual(peer?.petname, alice)
        XCTAssertEqual(peer?.since, version)
        
        try service.purgePeer(petname: alice)
        
        let syncInfo = try service.readPeer(identity: did)
        XCTAssertNil(syncInfo)
        
        let recent = try service.listRecentMemos(owner: did, includeDrafts: true)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(
            recent.first?.address,
            Slashlink(
                peer: Peer.did(Did.local),
                slug: Slug("bar")!
            )
        )
    }
    
    func testSearchRenameSuggestions() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        // Add some entries to DB
        let now = Date.now
        
        // This is a peer we are following
        let alice = Petname("alice")!
        let source = PeerRecord(
            petname: alice,
            identity: Did("did:key:alice")!,
            since: "bafyfakefakefake"
        )
        
        try service.writePeer(source)
        
        // Create a note, we will attempt to merge this into another note
        let current = Slashlink("/foo")!
        let foo = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Foo, published note, starting point."
        )
        
        let did = Did("did:key:abc123")!
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: nil,
                slug: current.slug,
                memo: foo
            )
        )
        
        // Contains link to /foo, should show up in merge results, local memo
        let bar = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar /foo should appear in results, local draft."
        )
        try service.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("bar")!,
                memo: bar,
                size: bar.toHeaderSubtext().size()!
            )
        )
        
        // Contains link to /foo, should show up in merge results, published memo
        let baz = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "Bar /foo should appear in results, local draft."
        )
        try service.writeMemo(
            MemoRecord(
                did: did,
                petname: Petname("abc")!,
                slug: Slug("bar2")!,
                memo: baz,
                size: baz.toHeaderSubtext().size()!
            )
        )
        
        // Someone else's content, never possible to merge, should be filtered out.
        let qux = Memo(
            contentType: "text/subtext",
            created: now,
            modified: now,
            fileExtension: "subtext",
            additionalHeaders: [],
            body: "This /foo should not appear in results, 3P."
        )
        try service.writeMemo(
            MemoRecord(
                did: source.identity,
                petname: alice,
                slug: Slug("food")!,
                memo: qux
            )
        )
        
        let search = try service.searchRenameSuggestions(owner: did, query: "fo", current: current)
        XCTAssert(search.count == 3)
        
        let first = search[0]
        switch first {
        case let .move(from, to):
            XCTAssert(from == current)
            XCTAssert(to.isOurs)
            XCTAssert(to.slug == Slug("fo"))
            break
        default:
            XCTFail("expected move result first")
        }
        
        let second = search[1]
        switch second {
        case let .merge(parent, child):
            XCTAssert(child == current)
            XCTAssert(parent.isOurs)
            XCTAssert(parent.isLocal)
            XCTAssert(parent.slug == Slug("bar"))
            break
        default:
            XCTFail("expected local merge result second")
        }
        
        let third = search[2]
        switch third {
        case let .merge(parent, child):
            XCTAssert(child == current)
            XCTAssert(parent.isOurs)
            XCTAssertFalse(parent.isLocal)
            XCTAssert(parent.slug == Slug("bar2"))
            break
        default:
            XCTFail("expected public merge result third")
        }
    }
    
    struct TestMetadata: Codable, Equatable {
        let foo: String
    }
    
    func testWriteActivity() throws {
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        try service.writeActivity(
            event: ActivityEvent(
                category: .system,
                event: "test_event",
                message: "test_message",
                metadata: TestMetadata(
                    foo: "bar"
                )
            )
        )
        
        let activities: [ActivityEvent<TestMetadata>] = try service.listActivityEventType(eventType: "test_event")
        
        XCTAssertEqual(activities.count, 1)
        let lastActivity = activities.first!
        
        XCTAssertEqual(lastActivity.category, .system)
        XCTAssertEqual(lastActivity.event, "test_event")
        XCTAssertEqual(lastActivity.message, "test_message")
        XCTAssertEqual(lastActivity.metadata, TestMetadata(foo: "bar"))
    }
    
    func testWriteNeighbor() throws {
        let identity = Did.dummyData()
        let peer = PeerRecord(petname: Petname.dummyData(), identity: Did.dummyData())
        
        let neighbor = NeighborRecord(
            petname: Petname.dummyData(),
            identity: Did.dummyData(),
            address: Slashlink.dummyData(),
            peer: peer.petname,
            since: Cid.dummyDataShort()
        )
        let neighbor2 = NeighborRecord(
            petname: Petname.dummyData(),
            identity: Did.dummyData(),
            address: Slashlink.dummyData(),
            peer: peer.petname,
            since: Cid.dummyDataShort()
        )
        
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        try service.writePeer(peer)
        try service.writeNeighbor(neighbor)
        try service.writeNeighbor(neighbor2)
        
        let results = try service.listNeighbors(owner: identity)
        XCTAssertEqual(results.count, 2)
        
        try service.removeNeighbor(
            neighbor: neighbor.petname,
            peer: neighbor.peer
        )
        
        let results2 = try service.listNeighbors(owner: identity)
        XCTAssertEqual(results2.count, 1)
    }
    
    func testExcludesSelfFromNeighbors() throws {
        let identity = Did.dummyData()
        let peer = PeerRecord(petname: Petname.dummyData(), identity: Did.dummyData())
        
        let neighbor = NeighborRecord(
            petname: Petname.dummyData(),
            identity: Did.dummyData(),
            address: Slashlink.dummyData(),
            peer: peer.petname,
            since: Cid.dummyDataShort()
        )
        let neighbor2 = NeighborRecord(
            petname: Petname.dummyData(),
            identity: identity,
            address: Slashlink.dummyData(),
            peer: peer.petname,
            since: Cid.dummyDataShort()
        )
        
        let service = try createDatabaseService()
        _ = try service.migrate()
        
        try service.writePeer(peer)
        try service.writeNeighbor(neighbor)
        try service.writeNeighbor(neighbor2)
        
        let results = try service.listNeighbors(owner: identity)
        XCTAssertEqual(results.count, 1)
        
        let results2 = try service.listNeighbors(owner: Did.dummyData())
        XCTAssertEqual(results2.count, 2)
    }
}
