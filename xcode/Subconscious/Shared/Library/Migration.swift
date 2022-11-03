//
//  Migration.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/22.
//

import Foundation

protocol MigrationProtocol {
    var version: Int { get }
    func migrate(_ connection: SQLite3Database.Connection) throws
}

/// A declarative SQL-only migration
struct SQLMigration: MigrationProtocol {
    var version: Int
    var sql: String

    func migrate(_ connection: SQLite3Database.Connection) throws {
        try connection.executescript(sql: sql)
    }
}

/// A custom migration that is defined via a migrate closure
struct Migration<Environment>: MigrationProtocol {
    var version: Int
    private var environment: Environment
    private var perform: (
        SQLite3Database.Connection,
        Environment
    ) throws -> Void
    
    init(
        version: Int,
        environment: Environment,
        perform: @escaping (
            SQLite3Database.Connection,
            Environment
        ) throws -> Void
    ) {
        self.version = version
        self.environment = environment
        self.perform = perform
    }
    
    func migrate(_ connection: SQLite3Database.Connection) throws {
        try self.perform(connection, self.environment)
    }
}

enum MigrationsError: Error {
    case migrationFailed(version: Int, error: String)
    case invalidVersion(Int)
}

struct Migrations {
    let migrations: [MigrationProtocol]
    
    init(
        _ migrations: [MigrationProtocol]
    ) {
        let migrations = migrations
            .sorted(by: { lhs, rhs in
                lhs.version < rhs.version
            })
        self.migrations = migrations
    }

    /// Applies migrations in sequence, skipping everything up to and including
    /// current version, then applying versions after that one by one.
    func migrate(_ database: SQLite3Database) throws -> Int {
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
                // Try migration
                try migration.migrate(connection)
                // Mark version
                try connection.executescript(
                    sql: """
                    PRAGMA user_version = \(migration.version);
                    """
                )
                // Release savepoint
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
