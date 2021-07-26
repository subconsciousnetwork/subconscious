//
//  SQLite3Migrations.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/11/21.
//

import Foundation
import Combine

//  MARK: SQLite3Migrations
struct SQLite3Migrations {
    enum SQLiteMigrationsError: Error {
        case invalidVersion(message: String)
        case migration(message: String)
    }

    struct Migration: Equatable, Comparable, Hashable {
        enum MigrationError: Error {
            case date(message: String)
        }

        static func < (lhs: Migration, rhs: Migration) -> Bool {
            lhs.version < rhs.version
        }

        let version: Int
        let sql: String

        init(version: Int, sql: String) {
            self.version = version
            self.sql = sql
        }

        init?(date: String, sql: String) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withFullDate,
                .withTime,
                .withDashSeparatorInDate,
                .withColonSeparatorInTime
            ]
            guard let date = formatter.date(from: date) else {
                return nil
            }
            self.init(
                date: date,
                sql: sql
            )
        }

        init(date: Date, sql: String) {
            self.init(version: Int(date.timeIntervalSince1970), sql: sql)
        }
    }

    let migrations: [Migration]

    var versions: [Int] {
        migrations.map({ migration in migration.version })
    }

    var latest: Migration {
        migrations.max()!
    }

    init?(_ migrations: [Migration]) {
        guard !migrations.isEmpty else {
            return nil
        }
        self.migrations = migrations
    }

    /// Allows for a quick check against latest migration version.
    /// Does not make sure that the version you supply is actually valid.
    func isMigrated(version: Int) -> Bool {
        return version == latest.version
    }

    /// Make sure the version supplied is a legit migration version.
    /// It must either be one of the versions in the migrations list, or the `DEFAULT_USER_VERSION`.
    func isValidVersion(version: Int) -> Bool {
        return (
            version == SQLite3Connection.DEFAULT_USER_VERSION ||
            self.versions.contains(version)
        )
    }

    /// Get migrations that need to be applied.
    func filterOutstandingMigrations(since version: Int) -> [Migration] {
        return migrations
            .sorted()
            .filter({ migration in migration.version > version })
    }
    
    // Information about successful migrations
    struct MigrationSuccess {
        let from: Int
        let to: Int
        let migrations: [Int]
    }
    
    /// Apply migrations to a database, skipping migrations that have already been applied.
    /// Versions MUST monotonically increase, and migrations will be sorted by version before being
    /// applied. It is recommended to use a UNIX time stamp as the version.
    ///
    /// All migrations are applied during same transaction. If any migration fails, the database is
    /// rolled back to its pre-migration state.
    ///
    /// - Returns: `(from: Int, to: Int)`, a tuple representing version
    @discardableResult func migrate(
        database: SQLite3Connection
    ) throws -> MigrationSuccess {
        let databaseVersion = try database.getUserVersion()

        // Make sure the current version is initial version, or
        // that it is some known migration version.
        guard isValidVersion(version: databaseVersion)
        else {
            throw SQLiteMigrationsError.invalidVersion(
                message: """
                Database version \(databaseVersion) does not match any version in migration list.
                Database version: \(databaseVersion)
                Valid versions: \(self.versions)
                """
            )
        }
        
        let outstandingMigrations = filterOutstandingMigrations(
            since: databaseVersion
        )

        if (outstandingMigrations.count > 0) {
            try database.executescript(sql: "SAVEPOINT premigration;")

            for migration in outstandingMigrations {
                do {
                    try database.executescript(sql: """
                    PRAGMA user_version = \(migration.version);
                    \(migration.sql)
                    """)
                } catch {
                    // If failure, roll back all changes to original savepoint.
                    // Note that ROLLBACK without a TO clause just backs everything
                    // out as if it never happened, whereas ROLLBACK TO rewinds
                    // to the beginning of the transaction. We want the former.
                    // https://sqlite.org/lang_savepoint.html
                    try database.executescript(
                        sql: "ROLLBACK TO SAVEPOINT premigration;"
                    )

                    throw SQLiteMigrationsError.migration(
                        message: """
                        Migration failed. Rolling back to pre-migration savepoint.
                        
                        Error: \(error)
                        """
                    )
                }
            }

            // We made it through all the migrations. Release savepoint.
            try database.executescript(sql: "RELEASE SAVEPOINT premigration;")
        }

        return MigrationSuccess(
            from: databaseVersion,
            to: self.latest.version,
            migrations: Array(
                outstandingMigrations.map({ migration in
                    migration.version
                })
            )
        )
    }
}

//  MARK: SQLiteMigrationsError extensions
extension SQLite3Migrations.SQLiteMigrationsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidVersion(let message):
            return """
            Invalid database version (SQLite3Migrations.SQLiteMigrationsError.invalidVersion)

            \(message)
            """
        case .migration(let message):
            return """
            Migration error (SQLite3Migrations.SQLiteMigrationsError.migration)

            \(message)
            """
        }
    }
}
