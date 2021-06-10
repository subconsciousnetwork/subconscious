//
//  Database.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//

import Foundation
import Combine
import os

//  MARK: Actions
enum DatabaseAction {
    /// Trigger a database migration.
    /// Does an early exit if version is up-to-date.
    /// All calls to the query interface in the environment perform these steps to ensure the
    /// schema is up-to-date before issuing a query.
    /// However it's a good idea to run this action when the app starts so that you get the expensive
    /// stuff out of the way early.
    case setup
    case setupSuccess
    case setupFailure
    /// Rebuild database if it is somehow impossible to migrate.
    /// This should not happen, but it allows us to recover if it does.
    case rebuild
    case sync
    case noop
}

//  MARK: Model
struct DatabaseModel: Equatable {
    enum State: Equatable {
        case unknown
        case setup
        case ready
        case broken
    }
    
    var state: State = .unknown
}

//  MARK: Update
func updateDatabase(
    state: inout DatabaseModel,
    action: DatabaseAction,
    environment: DatabaseEnvironment
) -> AnyPublisher<DatabaseAction, Never> {
    switch action {
    case .setup:
        state.state = .setup
        return environment.promiseMigrateDatabase()
            .map({ _ in DatabaseAction.setupSuccess })
            .replaceError(with: DatabaseAction.setupFailure)
            .eraseToAnyPublisher()
    case .setupSuccess:
        state.state = .ready
        return Just(DatabaseAction.sync).eraseToAnyPublisher()
    case .setupFailure:
        state.state = .broken
        return Just(DatabaseAction.rebuild).eraseToAnyPublisher()
    case .rebuild:
        return environment.promiseDeleteDatabase()
            .flatMap(environment.promiseMigrateDatabase)
            .map({ _ in DatabaseAction.setupSuccess })
            .replaceError(with: DatabaseAction.noop)
            .eraseToAnyPublisher()
    case .sync:
        return environment.promiseSyncDatabase()
            .map({ _ in DatabaseAction.noop })
            .replaceError(with: DatabaseAction.noop)
            .eraseToAnyPublisher()
    case .noop:
        return Empty().eraseToAnyPublisher()
    }
}

//  MARK: Environment
struct DatabaseEnvironment {
    static func getMigrations() -> SQLiteMigrations {
        return SQLiteMigrations([
            SQLiteMigrations.Migration(
                date: "2021-06-04T5:23:00",
                sql: """
                CREATE TABLE entry (
                  path TEXT PRIMARY KEY,
                  title TEXT NOT NULL,
                  body TEXT NOT NULL,
                  modified TEXT NOT NULL,
                  size INTEGER NOT NULL
                );

                CREATE VIRTUAL TABLE entry_search USING fts5(
                  path UNINDEXED,
                  title,
                  body,
                  modified UNINDEXED,
                  size UNINDEXED,
                  content="entry",
                  tokenize="porter"
                );

                /*
                Create triggers to keep fts5 virtual table in sync with content table.

                Note: SQLite documentation notes that you want to modify the fts table *before*
                the external content table, hence the BEFORE commands.

                These triggers are adapted from examples in the docs:
                https://www.sqlite.org/fts3.html#_external_content_fts4_tables_
                */
                CREATE TRIGGER entry_search_before_update BEFORE UPDATE ON entry BEGIN
                  DELETE FROM entry_search WHERE rowid=old.rowid;
                END;

                CREATE TRIGGER entry_search_before_delete BEFORE DELETE ON entry BEGIN
                  DELETE FROM entry_search WHERE rowid=old.rowid;
                END;

                CREATE TRIGGER entry_search_after_update AFTER UPDATE ON entry BEGIN
                  INSERT INTO entry_search
                    (
                      rowid,
                      path,
                      title,
                      body,
                      modified,
                      size
                    )
                  VALUES
                    (
                      new.rowid,
                      new.path,
                      new.title,
                      new.body,
                      new.modified,
                      new.size
                    );
                END;

                CREATE TRIGGER entry_search_after_insert AFTER INSERT ON entry BEGIN
                  INSERT INTO entry_search
                    (
                      rowid,
                      path,
                      title,
                      body,
                      modified,
                      size
                    )
                  VALUES
                    (
                      new.rowid,
                      new.path,
                      new.title,
                      new.body,
                      new.modified,
                      new.size
                    );
                END;
                """
            )!
        ])!
    }

    let log = Logger(
        subsystem: "com.subconscious.Subconscious",
        category: "database"
    )
    let fileManager = FileManager.default
    let databaseUrl: URL
    let documentsUrl: URL
    let migrations: SQLiteMigrations

    func openDatabase() throws -> SQLiteConnection {
        try SQLiteConnection(url: databaseUrl)
    }
    
    func migrateDatabase() throws {
        let db = try openDatabase()
        let version = try db.getUserVersion()
        do {
            log.notice("Performing database migration from \(version) to \(migrations.latest.version).")
            try migrations.migrate(database: db)
            log.notice("Database migration succeeded. Upgraded from \(version) to \(migrations.latest.version).")
        } catch {
            log.warning("Database migration failed. Rolling back to premigration snapshot."
            )
            throw error
        }
    }
    
    func promiseMigrateDatabase() -> Future<Void, Error> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                do {
                    try migrateDatabase()
                    promise(.success(Void()))
                } catch {
                    promise(.failure(error))
                }
            })
        })
    }
    
    func deleteDatabase() throws {
        log.notice("Deleting database")
        do {
            try fileManager.removeItem(at: databaseUrl)
            log.notice("Deleted database")
        } catch {
            log.warning("Failed to delete database")
            throw error
        }
    }
    
    func promiseDeleteDatabase() -> Future<Void, Error> {
        Future({ promise in
            do {
                try deleteDatabase()
                promise(.success(Void()))
            } catch {
                promise(.failure(error))
            }
        })
    }
    
    func writeEntry(_ url: URL) throws {
        let db = try openDatabase()
        let contents = try fileManager.contents(atPath: url.path).unwrap()
        let fingerprint = try FileSync.FileFingerprint(
            url: url,
            with: fileManager
        )
        let body = String(decoding: contents, as: UTF8.self)
        try db.execute(
            sql: """
            INSERT INTO entry (path, title, body, modified, size)
            VALUES (?, ?, ?, ?, ?)
            """,
            parameters: [
                // Must store relative path, since absolute path
                // can change during testing.
                .text(url.lastPathComponent),
                .text(url.stem),
                .text(body),
                .date(fingerprint.modified),
                .integer(fingerprint.size)
            ]
        )
    }
    
    func promiseWriteEntry(_ url: URL) -> Future<Void, Error> {
        Future({ promise in
            do {
                try writeEntry(url)
                promise(.success(Void()))
            } catch {
                promise(.failure(error))
            }
        })
    }
    
    func removeEntry(_ url: URL) throws {
        let db = try openDatabase()
        try db.execute(
            sql: """
            DELETE FROM entry WHERE path = ?
            """,
            parameters: [
                .text(url.lastPathComponent)
            ]
        )
    }

    func promiseRemoveEntry(_ url: URL) -> Future<Void, Error> {
        Future({ promise in
            do {
                try removeEntry(url)
                promise(.success(Void()))
            } catch {
                promise(.failure(error))
            }
        })
    }
    
    func syncDatabase() throws {
        log.info("Syncing database")
        do {
            let fileUrls = try fileManager.contentsOfDirectory(
                at: documentsUrl,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ).withPathExtension("subtext")

            // Left = Leader (files)
            let left = try FileSync.readFileFingerprints(
                urls: fileUrls,
                with: fileManager
            )

            let db = try openDatabase()

            // Right = Follower (search index)
            let right = try db.execute(
                sql: "SELECT path, modified, size FROM entry"
            ).map({ row  in
                FileSync.FileFingerprint(
                    url: URL(
                        fileURLWithPath: try row[0]
                            .asString()
                            .unwrap(),
                        relativeTo: documentsUrl
                    ),
                    modified: try row[1].asDate().unwrap(),
                    size: try row[2].asInt().unwrap()
                )
            })
            
            let changes = FileSync.calcChanges(
                left: left,
                right: right
            )

            for change in changes {
                switch change.status {
                // .leftOnly = create.
                // .leftNewer = update.
                // .rightNewer = ??? Follower should not be ahead. Leader wins.
                // .conflict. Leader wins.
                case .leftOnly, .leftNewer, .rightNewer, .conflict:
                    if let left = change.left {
                        try writeEntry(left.url)
                    }
                // .rightOnly = delete. Remove from search index
                case .rightOnly:
                    if let right = change.right {
                        try removeEntry(right.url)
                    }
                // .same = no change. Do nothing.
                case .same:
                    break
                }
            }
            log.info("Database sync finished")
        } catch {
            log.warning("Database sync failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func promiseSyncDatabase() -> Future<Void, Error> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                do {
                    try syncDatabase()
                    promise(.success(Void()))
                } catch (let error) {
                    promise(.failure(error))
                }
            })
        })
    }
}
