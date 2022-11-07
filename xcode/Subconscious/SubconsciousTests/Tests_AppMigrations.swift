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
        let migrations = Config.migrations
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
        let memos = HeaderSubtextMemoStore(store: memoryStore)

        try memos.write(
            Slug("loomings")!,
            value: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Loomings",
                fileExtension: ContentType.subtext.fileExtension,
                other: [],
                body: "Call me Ishmael."
            )
        )

        /// Write incomplete file
        try memoryStore.write(
            "oysters.subtext",
            value: """
            Title: Too much like oysters
            Created: 2022-11-04T19:52:09Z
            Modified: 2022-11-04T19:52:40Z

            We are too much like oysters observing the sun through the water, and thinking that thick water the thinnest of air.
            """.toData()!
        )

        let migrations = Config.migrations

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
        let loomings = try memos.read(Slug("loomings")!)
        XCTAssertEqual(loomings.title, "Loomings")
        XCTAssertEqual(loomings.body, "Call me Ishmael.")

        let oysters = try memos.read(Slug("oysters")!)
        XCTAssertEqual(oysters.title, "Too much like oysters")
        XCTAssertEqual(oysters.body, "We are too much like oysters observing the sun through the water, and thinking that thick water the thinnest of air.")
        XCTAssertEqual(
            oysters.created,
            Date.from("2022-11-04T19:52:09Z")
        )
        XCTAssertEqual(
            oysters.modified,
            Date.from("2022-11-04T19:52:40Z")
        )
    }
}
