//
//  Migration.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/22.
//

import Foundation

enum MigrationError: Error {
    case invalidParent(expected: Int, actual: Int)
    case migrationFailed(version: Int, error: String)
}

/// A migration is a combination of a Schema plus some
struct Migration<Environment>: Equatable, Identifiable, Comparable {
    static func < (lhs: Migration<Environment>, rhs: Migration<Environment>) -> Bool {
        lhs.version < rhs.version
    }
    
    static func == (lhs: Migration<Environment>, rhs: Migration<Environment>) -> Bool {
        lhs.version == rhs.version
    }

    var parent: Int
    /// Migration version. Written into database after successful migration.
    var version: Int
    var sql: String
    /// Actions to perform during migration.
    var perform: ((SQLite3Database.Connection, Environment) throws -> Void)?
    
    var id: Int { version }

    /// Apply migration to database and store.
    ///
    /// Checks to ensure database is at expected version.
    /// Applies migration SQL and `after` logic. If either fail, rolls database
    /// back to last savepoint.
    func apply(
        connection: SQLite3Database.Connection,
        environment: Environment
    ) throws -> Int {
        let parent = try connection.getUserVersion()
        guard parent == self.parent else {
            throw MigrationError.invalidParent(
                expected: self.parent,
                actual: parent
            )
        }
        // Mark rollback savepoint
        try connection.executescript(sql: "SAVEPOINT premigration;")
        do {
            // Attempt SQL migration
            try connection.executescript(
                sql: """
                PRAGMA user_version = \(self.version);
                \(sql)
                """
            )
            // Attempt manual migration steps
            if let perform = self.perform {
                try perform(connection, environment)
            }
        } catch {
            // If failure, roll back all changes to original savepoint.
            // Note that ROLLBACK without a TO clause just backs everything
            // out as if it never happened, whereas ROLLBACK TO rewinds
            // to the beginning of the transaction. We want the former.
            // https://sqlite.org/lang_savepoint.html
            try connection.executescript(
                sql: "ROLLBACK TO SAVEPOINT premigration;"
            )
            throw MigrationError.migrationFailed(
                version: version,
                error: error.localizedDescription
            )
        }
        return self.version
    }
}

struct Migrations<Environment> {
    let migrations: [Migration<Environment>]
    
    init(
        _ migrations: [Migration<Environment>]
    ) {
        let migrations = migrations.sorted()
        self.migrations = migrations
    }

    /// Applies migrations in sequence, skipping everything up to and including
    /// current version, then applying versions after that one by one.
    func migrate(
        database: SQLite3Database,
        environment: Environment
    ) throws -> Int {
        let connection = try database.open()
        var version = try connection.getUserVersion()
        for migration in migrations {
            if migration.version <= version {
                continue
            }
            version = try migration.apply(
                connection: connection,
                environment: environment
            )
        }
        return version
    }
}
