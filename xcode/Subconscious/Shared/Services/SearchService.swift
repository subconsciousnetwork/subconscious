//
//  SearchService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//

import Foundation
import Combine

struct SearchService {
    private let fileManager = FileManager.default
    private let db: SQLiteConnection
    private let documentDirectory: URL

    enum SearchServiceError: Error {
        case documentDirectory
        case indexWriteError
    }
    
    init(databaseUrl: URL) throws {
        self.db = try SQLiteConnection(url: databaseUrl)
        self.documentDirectory = try fileManager.documentDirectoryUrl
            .unwrap(or: SearchServiceError.documentDirectory)
        try self.migrate()
    }
    
    /// Migrate is idempotent and cheap to run. You can safely run it once on every startup to
    /// ensure DB is up to date.
    private func migrate() throws {
        let migrations = SQLiteMigrations([
            try SQLiteMigrations.Migration(
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
            )
        ])

        if try !migrations.isMigrated(db: db) {
            let databaseVersion = try db.getUserVersion()
            let latestVersion = try migrations.latest.unwrap().version
            let outstandingMigrations = try migrations
                .filterOutstandingMigrations(since: databaseVersion)

            log.notice("""
            Database schema out of date. Applying migrations.
            Database: \(databaseVersion)
            Latest: \(latestVersion)
            Migrations: \(outstandingMigrations.count)
            """)
            do {
                try migrations.migrate(db: db)
                log.notice("Database migration successful")
            } catch {
                log.critical(
                    """
                    Database migration failed.
                    Rolled back to pre-migration savepoint.
                    """
                )
            }
        } else {
            log.info("Database schema up-to-date")
        }
    }
    
    @discardableResult func writeToIndex(_ url: URL) -> Future<Void, Error> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                do {
                    if let contents = fileManager.contents(atPath: url.path) {
                        let fingerprint = try FileSync.FileFingerprint.from(
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
                                .text(url.absoluteString),
                                .text(url.stem),
                                .text(body),
                                .date(fingerprint.modified),
                                .integer(fingerprint.size)
                            ]
                        )
                        promise(.success(()))
                    } else {
                        promise(.failure(SearchServiceError.indexWriteError))
                    }
                } catch {
                    promise(.failure(SearchServiceError.indexWriteError))
                }
            })
        })
    }

    @discardableResult func removeFromIndex(_ url: URL) -> Future<Bool, Never> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                print("SearchService.removeFromIndex")
                promise(.success(true))
            })
        })
    }
    
    func syncIndex() -> Future<Void, Error> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                do {
                    let fileUrls = try fileManager.contentsOfDirectory(
                        at: documentDirectory,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles
                    ).withPathExtension("subtext")


                    // Left = Leader (files)
                    let left = try FileSync.readFileFingerprints(
                        urls: fileUrls,
                        with: fileManager
                    )

                    // Right = Follower (search index)
                    let right = try db.execute(
                        sql: "SELECT path, modified, size FROM entry"
                    ).map({ row  in
                        FileSync.FileFingerprint(
                            url: URL(
                                fileURLWithPath: try row[0]
                                    .asString()
                                    .unwrap()
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
                                self.writeToIndex(left.url)
                            }
                        // .rightOnly = delete. Remove from search index
                        case .rightOnly:
                            if let right = change.right {
                                self.removeFromIndex(right.url)
                            }
                        // .same = no change. Do nothing.
                        case .same:
                            break
                        }
                    }

                    promise(.success(()))
                } catch (let error) {
                    promise(.failure(error))
                }
            })
        })
    }
}
