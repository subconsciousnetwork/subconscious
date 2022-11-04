//
//  Tests_AppMigrations.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 11/3/22.
//

import XCTest
@testable import Subconscious

final class Tests_AppMigrations: XCTestCase {
    func testMigrations() throws {
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
}
