//
//  Tests_Migrations.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 11/3/22.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

final class Tests_Migrations: XCTestCase {
    func testMigrationMigrate() throws {
        let v1 = SQLMigration(
            version: 1,
            sql: """
            CREATE TABLE entry (
              slug TEXT PRIMARY KEY,
              title TEXT NOT NULL DEFAULT '',
              body TEXT NOT NULL,
              modified TEXT NOT NULL,
              size INTEGER NOT NULL
            );
            """
        )
        
        let v2 = SQLMigration(
            version: 2,
            sql: """
            DROP TABLE entry;
            CREATE TABLE note (
              slug TEXT PRIMARY KEY,
              title TEXT NOT NULL DEFAULT '',
              body TEXT NOT NULL,
              modified TEXT NOT NULL,
              size INTEGER NOT NULL
            );
            """
        )
        
        let migrations = Migrations([v1, v2])
        let db = SQLite3Database(path: ":memory:")
        let version = try migrations.migrate(db)
        XCTAssertEqual(version, 2)
    }
    
    func testMigrationRollback() throws {
        let v1 = SQLMigration(
            version: 1,
            sql: """
            CREATE TABLE entry (
              slug TEXT PRIMARY KEY,
              title TEXT NOT NULL DEFAULT '',
              body TEXT NOT NULL,
              modified TEXT NOT NULL,
              size INTEGER NOT NULL
            );
            """
        )

        let v2 = SQLMigration(
            version: 2,
            sql: """
            DROP TABLE does_not_exist;
            """
        )

        let migrations = Migrations([v1, v2])
        let db = SQLite3Database(path: ":memory:")
        do {
            _ = try migrations.migrate(db)
        } catch {
            XCTAssert(true)
        }
        let version = try db.open().getUserVersion()
        XCTAssertEqual(version, 1, "Rolls back to last good version")
    }
}
