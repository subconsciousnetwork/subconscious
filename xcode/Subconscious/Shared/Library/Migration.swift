//
//  Migration.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/22.
//

import Foundation

enum MigrationError: Error {
    case invalidParent(expected: Int, actual: Int)
    case migrationFailed(rollback: Int, error: String)
}

/// A migration is a combination of a Schema plus some
struct Migration<Store>: Equatable, Identifiable, Comparable {
    static func < (lhs: Migration<Store>, rhs: Migration<Store>) -> Bool {
        lhs.version < rhs.version
    }
    
    static func == (lhs: Migration<Store>, rhs: Migration<Store>) -> Bool {
        lhs.version == rhs.version
    }

    /// A migration describes a transition between two versions.
    /// We require an parent version to make this relationship explicit,
    /// so as to avoid errors.
    var parent: Int
    /// Migration version. Written into database.
    var version: Int
    /// SQL to perform during migration
    var sql: String
    /// Additional actions to perform after SQL migration.
    var after: (SQLite3Database, Store) throws -> Void
    
    var id: Int { version }

    /// Apply migration to database and store.
    ///
    /// Checks to ensure database is at expected version.
    /// Applies migration SQL and `after` logic. If either fail, rolls database
    /// back to last savepoint.
    func apply(
        database: SQLite3Database,
        store: Store
    ) throws -> Int {
        let parent = try database.getUserVersion()
        guard self.parent == parent else {
            throw MigrationError.invalidParent(
                expected: self.parent,
                actual: parent
            )
        }
        let connection = try database.open()
        try connection.executescript(sql: "SAVEPOINT premigration;")
        do {
            try database.executescript(
                sql: """
                PRAGMA user_version = \(self.version);
                \(self.sql)
                """
            )
            try after(database, store)
        } catch {
            // If failure, roll back all changes to original savepoint.
            // Note that ROLLBACK without a TO clause just backs everything
            // out as if it never happened, whereas ROLLBACK TO rewinds
            // to the beginning of the transaction. We want the former.
            // https://sqlite.org/lang_savepoint.html
            try database.executescript(
                sql: "ROLLBACK TO SAVEPOINT premigration;"
            )
            throw MigrationError.migrationFailed(
                rollback: self.parent,
                error: error.localizedDescription
            )
        }
        return self.version
    }
}

extension Migration {
    /// Create a version integer from an ISO8601 date string.
    /// - Returns an int that represents seconds since Unix epoch to date.
    static func version(iso8601String: String) -> Int? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate,
            .withTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime
        ]
        guard let date = formatter.date(from: iso8601String) else {
            return nil
        }
        return Int(date.timeIntervalSince1970)
    }
}

struct Migrations<Store> {
    let migrations: [Migration<Store>]
    
    init(
        migrations: [Migration<Store>]
    ) {
        let migrations = migrations.sorted()
        self.migrations = migrations
    }

    /// Applies migrations in sequence, skipping everything up to and including
    /// current version, then applying versions after that one by one.
    func migrate(
        database: SQLite3Database,
        store: Store
    ) throws -> [Int] {
        let version = try database.getUserVersion()
        var applied: [Int] = []
        for migration in migrations {
            if migration.version <= version {
                continue
            }
            let version = try migration.apply(database: database, store: store)
            applied.append(version)
        }
        return applied
    }
}
