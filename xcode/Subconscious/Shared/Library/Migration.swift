//
//  Migration.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/22.
//

import Foundation

protocol MigrationProtocol {
    var version: Int { get }
    func migrate(_ connection: SQLite3Database) throws
}

/// A declarative SQL-only migration
struct SQLMigration: MigrationProtocol {
    var version: Int
    var sql: String

    func migrate(_ database: SQLite3Database) throws {
        try database.executescript(sql: sql)
    }
}

/// A custom migration that is defined via a migrate closure
struct Migration<Environment>: MigrationProtocol {
    var version: Int
    private var environment: Environment
    private var perform: (
        SQLite3Database,
        Environment
    ) throws -> Void

    init(
        version: Int,
        environment: Environment,
        perform: @escaping (
            SQLite3Database,
            Environment
        ) throws -> Void
    ) {
        self.version = version
        self.environment = environment
        self.perform = perform
    }

    func migrate(_ database: SQLite3Database) throws {
        try self.perform(database, self.environment)
    }
}

enum MigrationsError: Error, LocalizedError {
    case migrationFailed(version: Int, error: String)
    case invalidVersion(Int)
    
    var errorDescription: String? {
        switch self {
        case let .migrationFailed(version, error):
            return "migrationFailed(\(version), \(error))"
        case let .invalidVersion(version):
            return "invalidVersion(\(version))"
        }
    }
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
        let version = try database.getUserVersion()
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
            try database.executescript(sql: "SAVEPOINT premigration;")
            do {
                // Try migration
                try migration.migrate(database)
                // Mark version
                try database.executescript(
                    sql: """
                    PRAGMA user_version = \(migration.version);
                    """
                )
                // Release savepoint
                try database.executescript(
                    sql: "RELEASE SAVEPOINT premigration;"
                )
            } catch {
                // If failure, roll back all changes to original savepoint.
                // Note that ROLLBACK without a TO clause just backs everything
                // out as if it never happened, whereas ROLLBACK TO rewinds
                // to the beginning of the transaction. We want the former.
                // https://sqlite.org/lang_savepoint.html
                try database.executescript(
                    sql: "ROLLBACK TO SAVEPOINT premigration;"
                )
                throw MigrationsError.migrationFailed(
                    version: migration.version,
                    error: error.localizedDescription
                )
            }
        }
        return try database.getUserVersion()
    }
}
