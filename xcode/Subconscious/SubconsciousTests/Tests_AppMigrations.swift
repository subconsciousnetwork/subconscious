//
//  Tests_AppMigrations.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 11/3/22.
//

import XCTest
@testable import Subconscious

final class Tests_AppMigrations: XCTestCase {
    func testBasicMigrations() throws {
        let db = SQLite3Database(path: ":memory:")
        let memoryStore = MemoryStore()
        let memoStore = MemoStore(store: memoryStore)
        let environment = AppMigrationEnvironment(
            files: memoryStore,
            memos: memoStore
        )
        let migrations = Config.migrations(environment)
        guard let latest = migrations.migrations.last?.version else {
            XCTFail("Could not unwrap latest migration")
            return
        }
        let version = try migrations.migrate(db)
        XCTAssertEqual(
            version,
            latest,
            "Migrated to latest version"
        )
    }
    
    func testOldContentMigrations() throws {
        let db = SQLite3Database(path: ":memory:")
        let memoryStore = MemoryStore()

        try memoryStore.write(
            "loomings.subtext",
            value: """
            Content-Type: text/subtext
            Title: Loomings
            
            Call me Ishmael.
            """.toData()!
        )

        try memoryStore.write(
            "oysters.subtext",
            value: """
            Content-Type: text/subtext
            Title: Oysters
            
            We are too much like oysters observing the sun through the water, and thinking that thick water the thinnest of air.
            """.toData()!
        )

        let memoStore = MemoStore(store: memoryStore)

        let environment = AppMigrationEnvironment(
            files: memoryStore,
            memos: memoStore
        )
        let migrations = Config.migrations(environment)

        guard let latest = migrations.migrations.last?.version else {
            XCTFail("Could not unwrap latest migration")
            return
        }

        let version = try migrations.migrate(db)

        XCTAssertEqual(
            version,
            latest,
            "Migrated to latest version"
        )
        let loomings = try memoStore.read(Slug("loomings")!)
        XCTAssertEqual(loomings.title, "Loomings")
        XCTAssertEqual(loomings.body, "We are too much like oysters observing the sun through the water, and thinking that thick water the thinnest of air.")
        let oysters = try memoStore.read(Slug("oysters")!)
        XCTAssertEqual(oysters.title, "Oysters")
        XCTAssertEqual(loomings.body, "Call me Ishmael.")
    }
}
