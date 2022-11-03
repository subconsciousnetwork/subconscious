//
//  Migration.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/22.
//

import Foundation

/// A migration is a combination of a Schema plus some
struct Migration<Environment>: Equatable, Identifiable, Comparable {
    static func < (
        lhs: Migration<Environment>,
        rhs: Migration<Environment>
    ) -> Bool {
        lhs.version < rhs.version
    }
    
    static func == (
        lhs: Migration<Environment>,
        rhs: Migration<Environment>
    ) -> Bool {
        lhs.version == rhs.version
    }

    /// Migration version. Written into database after successful migration.
    var version: Int
    var sql: String
    /// Actions to perform during migration.
    var perform: ((SQLite3Database.Connection, Environment) throws -> Void)?
    
    var id: Int { version }
}

enum MigrationsError: Error {
    case migrationFailed(version: Int, error: String)
    case invalidVersion(Int)
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
        var versions: Set<Int> = Set(
            migrations.map({ migration in migration.version })
        )
        versions.insert(0)
        guard versions.contains(version) else {
            throw MigrationsError.invalidVersion(version)
        }
        for migration in migrations {
            if migration.version <= version {
                continue
            }
            // Mark rollback savepoint
            try connection.executescript(sql: "SAVEPOINT premigration;")
            do {
                // Attempt SQL migration
                try connection.executescript(
                    sql: """
                    PRAGMA user_version = \(migration.version);
                    \(migration.sql)
                    """
                )
                // Attempt manual migration steps
                if let perform = migration.perform {
                    try perform(connection, environment)
                }
                try connection.executescript(
                    sql: "RELEASE SAVEPOINT premigration;"
                )
            } catch {
                // If failure, roll back all changes to original savepoint.
                // Note that ROLLBACK without a TO clause just backs everything
                // out as if it never happened, whereas ROLLBACK TO rewinds
                // to the beginning of the transaction. We want the former.
                // https://sqlite.org/lang_savepoint.html
                try connection.executescript(
                    sql: "ROLLBACK TO SAVEPOINT premigration;"
                )
                throw MigrationsError.migrationFailed(
                    version: migration.version,
                    error: error.localizedDescription
                )
            }
        }
        return try connection.getUserVersion()
    }
}
