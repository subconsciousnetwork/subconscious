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
    case log(_ action: LoggerAction)
    /// Trigger a database migration.
    /// Does an early exit if version is up-to-date.
    /// All calls to the query interface in the environment perform these steps to ensure the
    /// schema is up-to-date before issuing a query.
    /// However it's a good idea to run this action when the app starts so that you get the expensive
    /// stuff out of the way early.
    case setup
    case setupSuccess(_ success: SQLiteMigrations.MigrationSuccess)
    /// Rebuild database if it is somehow impossible to migrate.
    /// This should not happen, but it allows us to recover if it does.
    case rebuild
    /// Sync files with database
    case sync
    /// Perform a search with query string
    case search(_ query: String)
    case searchSuccess([TextFile])
    /// Perform a search over suggestions with query string
    case searchSuggestions(_ query: String)
    /// Search suggestion success with array of results
    case searchSuggestionsSuccess(_ results: [Suggestion])
}

//  MARK: Tagging functions
func tagDatabaseLoggerAction(_ action: LoggerAction) -> DatabaseAction {
    .log(action)
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
    case .log(let action):
        LoggerAction.log(
            action: action,
            environment: environment.logger
        )
    case .setup:
        state.state = .setup
        return environment.migrateDatabaseAsync()
            .map({ success in DatabaseAction.setupSuccess(success) })
            .replaceError(with: DatabaseAction.rebuild)
            .eraseToAnyPublisher()
    case .setupSuccess(let success):
        state.state = .ready
        if success.from == success.to {
            environment.logger.info("Database up-to-date. No migration needed")
        } else {
            environment.logger.info(
                "Database migrated from \(success.from) to \(success.to) via \(success.migrations)"
            )
        }
        return Just(DatabaseAction.sync).eraseToAnyPublisher()
    case .rebuild:
        state.state = .broken
        environment.logger.warning(
            "Database is broken or has wrong schema. Attempting to rebuild."
        )
        return environment.deleteDatabaseAsync()
            .flatMap(environment.migrateDatabaseAsync)
            .map({ success in DatabaseAction.setupSuccess(success) })
            .replaceError(
                with: .log(.critical("Failed to rebuild database"))
            )
            .eraseToAnyPublisher()
    case .sync:
        return environment.syncDatabaseAsync()
            .map({ _ in .log(.info("File sync done")) })
            .replaceError(with: .log(.error("File sync failed")))
            .eraseToAnyPublisher()
    case .search(let query):
        return environment.search(query: query)
            .map({ results in .searchSuccess(results) })
            .replaceError(with: .log(.error("Search failed")))
            .eraseToAnyPublisher()
    case .searchSuccess:
        environment.logger.warning(
            "DatabaseAction.searchSuccess should be handled by parent component"
        )
    case .searchSuggestions(let query):
        return environment.searchSuggestions(query: query)
            .map({ results in .searchSuggestionsSuccess(results) })
            .replaceError(with: .log(.error("Query search failed")))
            .eraseToAnyPublisher()
    case .searchSuggestionsSuccess:
        environment.logger.warning(
            "DatabaseAction.searchQueriesSuccess should be handled by parent component"
        )
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: Environment
struct DatabaseEnvironment {
    static func getMigrations() -> SQLiteMigrations {
        return SQLiteMigrations([
            SQLiteMigrations.Migration(
                date: "2021-06-14T16:22:00",
                sql: """
                CREATE TABLE search (
                    id TEXT PRIMARY KEY,
                    query TEXT NOT NULL,
                    created TEXT NOT NULL
                );

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

    let logger = Logger(
        subsystem: "com.subconscious.Subconscious",
        category: "database"
    )
    let fileManager = FileManager.default
    let databaseUrl: URL
    let documentsUrl: URL
    let migrations: SQLiteMigrations

    func migrateDatabaseAsync() ->
        AnyPublisher<SQLiteMigrations.MigrationSuccess, Error> {
        migrations.migrateAsync(
            path: databaseUrl.path,
            qos: .utility
        )
    }

    func deleteDatabaseAsync() -> AnyPublisher<Void, Error> {
        CombineUtilities.async(execute: {
            logger.notice("Deleting database")
            do {
                try fileManager.removeItem(at: databaseUrl)
                logger.notice("Deleted database")
            } catch {
                logger.warning("Failed to delete database: \(error.localizedDescription)")
                throw error
            }
        })
    }

    func syncDatabaseAsync() -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
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

            let db = try SQLiteConnection(
                path: databaseUrl.path,
                qos: .utility
            ).unwrap()

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
                // .rightNewer = Follower shouldn't be ahead.
                //               Leader wins.
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
        }
    }
    
    func writeEntry(_ url: URL) throws {
        let textFile = try TextFile(url: url).unwrap()
        try SQLiteConnection(path: databaseUrl.path).unwrap().execute(
            sql: """
            INSERT INTO entry (path, title, body, modified, size)
            VALUES (?, ?, ?, ?, ?)
            """,
            parameters: [
                // Must store relative path, since absolute path
                // can change during testing.
                .text(url.lastPathComponent),
                .text(url.stem),
                .text(textFile.content),
                .date(textFile.attributes.modified),
                .integer(textFile.attributes.size)
            ]
        )
    }
    
    func writeEntryAsync(_ url: URL) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try writeEntry(url)
        }
    }
    
    func removeEntry(_ url: URL) throws {
        try SQLiteConnection(path: databaseUrl.path)
            .unwrap()
            .execute(
                sql: """
                DELETE FROM entry WHERE path = ?
                """,
                parameters: [
                    .text(url.lastPathComponent)
                ]
            )
    }

    func removeEntryAsync(_ url: URL) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try removeEntry(url)
        }
    }

    /// Search through query strings
    func searchSuggestions(query: String) -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            let db = try SQLiteConnection(
                path: databaseUrl.path,
                qos: .userInitiated
            ).unwrap()
            
            let quoted = SQLiteConnection.quotePrefixQueryFTS5(query)
            
            let rows = try db.execute(
                sql: """
                SELECT title
                FROM entry_search
                WHERE entry_search.title MATCH ?
                ORDER BY rank
                LIMIT 8
                """,
                parameters: [
                    SQLiteConnection.SQLValue.text(quoted)
                ]
            )

            var threads = try rows.compactMap({ row in
                try Suggestion.thread(row[0].asString().unwrap())
            })

            if !query.isWhitespace {
                let create = Suggestion.create(query)
                threads.append(create)
            }

            return threads
        })
    }
    
    func search(query: String) -> AnyPublisher<[TextFile], Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            let db = try SQLiteConnection(
                path: databaseUrl.path,
                qos: .userInitiated
            ).unwrap()
            
            let quoted = SQLiteConnection.quoteQueryFTS5(query)

            let rows = try db.execute(
                sql: """
                SELECT path, body, modified, size
                FROM entry_search
                WHERE entry_search MATCH ?
                ORDER BY rank
                LIMIT 100
                """,
                parameters: [
                    SQLiteConnection.SQLValue.text(quoted)
                ]
            )

            return try rows.map({ row in
                let path = try row[0].asString().unwrap()
                let content = try row[1].asString().unwrap()
                let modified = try row[2].asDate().unwrap()
                let size = try row[3].asInt().unwrap()
                return TextFile(
                    url: documentsUrl.appendingPathComponent(path),
                    content: content,
                    modified: modified,
                    size: size
                )
            })
        })
    }
}
