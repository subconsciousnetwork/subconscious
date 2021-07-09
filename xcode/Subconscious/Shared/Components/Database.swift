//
//  Database.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//
//  Handles reading, writing, building, and syncing files and database.

import Foundation
import Combine
import os

//  TODO: consider moving search results and suggestions into database model
//  or else merge database model into App root.
//  We want database to be a component, so it can manage the complex lifecycle
//  aspects of migration as a component state machine. Yet most of the query
//  results themselves are stored elsewhere. This is ok, but feels awkward.

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
    case setupSuccess(_ success: SQLite3Migrations.MigrationSuccess)
    /// Rebuild database if it is somehow impossible to migrate.
    /// This should not happen, but it allows us to recover if it does.
    case rebuild
    /// Sync files with database
    case sync
    /// Perform a search with query string
    case search(_ query: String)
    case searchSuccess([TextDocument])
    /// Perform a search over suggestions with query string
    case searchSuggestions(_ query: String)
    /// Search suggestion success with array of results
    case searchSuggestionsSuccess(_ results: [Suggestion])
    /// Suggest titles for entry
    case searchTitleSuggestions(_ query: String)
    /// Title suggestion success with array of results
    case searchTitleSuggestionsSuccess(_ results: [Suggestion])
    /// Write to the file system and database.
    /// This acts like an upsert. If file exists, it will be overwritten, and DB updated.
    /// If file does not exist, it will be created.
    case writeDocument(url: URL?, content: String)
    case deleteDocument(url: URL)
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
        environment.logger.log("File sync started")
        return environment.syncDatabaseAsync()
            .map({ _ in .log(.info("File sync done")) })
            .replaceError(with: .log(.error("File sync failed")))
            .eraseToAnyPublisher()
    case .writeDocument(let url, let content):
        let title = Truncate.getFirstPseudoSentence(
            Subtext.getTitle(markup: content)
        )
        
        let concreteURL = url ?? environment.documentsUrl.appendingFilename(
            name: Slug.toSlugWithDate(title),
            ext: "subtext"
        )

        return environment.writeDocumentAsync(
            url: concreteURL,
            title: title,
            content: content
        )
        .map({ _ in .log(.info("Wrote document: \(concreteURL)")) })
        .replaceError(
            with: .log(.warning("Write failed for document: \(concreteURL)"))
        )
        .eraseToAnyPublisher()
    case .deleteDocument(let url):
        return environment.deleteDocumentAsync(url)
            .map({ _ in .log(.info("Deleted document: \(url)")) })
            .replaceError(
                with: .log(.warning("Delete failed for document: \(url)"))
            )
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
        return environment.searchSuggestions(query)
            .map({ results in .searchSuggestionsSuccess(results) })
            .replaceError(
                with: .log(.error("DatabaseAction.searchSuggestions failed"))
            ).eraseToAnyPublisher()
    case .searchSuggestionsSuccess:
        environment.logger.warning(
            "DatabaseAction.searchSuggestionsSuccess should be handled by parent component"
        )
    case .searchTitleSuggestions(let query):
        return environment.searchTitleSuggestions(query)
            .map({ results in .searchTitleSuggestionsSuccess(results) })
            .replaceError(
                with: .log(
                    .error(
                        "DatabaseAction.searchTitleSuggestions failed"
                    )
                )
            ).eraseToAnyPublisher()
    case .searchTitleSuggestionsSuccess:
        environment.logger.warning(
            "DatabaseAction.suggestTitlesSuccess should be handled by parent component"
        )
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: Environment
struct DatabaseEnvironment {
    static func getMigrations() -> SQLite3Migrations {
        return SQLite3Migrations([
            SQLite3Migrations.Migration(
                date: "2021-07-01T15:43:00",
                sql: """
                CREATE TABLE search_history (
                    id TEXT PRIMARY KEY,
                    query TEXT NOT NULL,
                    created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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

    private let db: SQLite3Connection
    
    let logger = Logger(
        subsystem: "com.subconscious.Subconscious",
        category: "database"
    )
    let fileManager = FileManager.default
    let databaseUrl: URL
    let documentsUrl: URL
    let migrations: SQLite3Migrations

    init(
        databaseUrl: URL,
        documentsUrl: URL,
        migrations: SQLite3Migrations
    ) throws {
        self.db = try SQLite3Connection(
            path: databaseUrl.absoluteString,
            mode: .readwrite
        )
        self.databaseUrl = databaseUrl
        self.documentsUrl = documentsUrl
        self.migrations = migrations
    }
    
    func migrateDatabaseAsync() ->
        AnyPublisher<SQLite3Migrations.MigrationSuccess, Error> {
        migrations.migrateAsync(database: self.db)
    }

    func deleteDatabaseAsync() -> AnyPublisher<Void, Error> {
        CombineUtilities.async(execute: {
            logger.notice("Deleting database")
            do {
                self.db.close()
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
            let left = try FileSync.readFileFingerprints(urls: fileUrls)

            // Right = Follower (search index)
            let right = try db.execute(
                sql: "SELECT path, modified, size FROM entry"
            ).map({ row  in
                FileFingerprint(
                    url: URL(
                        fileURLWithPath: try row.get(0).unwrap(),
                        relativeTo: documentsUrl
                    ),
                    modified: try row.get(1).unwrap(),
                    size: try row.get(2).unwrap()
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
                        try writeDocumentToDatabase(left.url)
                    }
                // .rightOnly = delete. Remove from search index
                case .rightOnly:
                    if let right = change.right {
                        try deleteDocumentFromDatabase(right.url)
                    }
                // .same = no change. Do nothing.
                case .same:
                    break
                }
            }
        }
    }

    /// Write document syncronously
    private func writeDocumentToDatabase(
        url: URL,
        title: String,
        content: String,
        modified: Date,
        size: Int
    ) throws {
        // Must store relative path, since absolute path of user documents
        // directory can be changed by system.
        let path = try url.relativizingPath(relativeTo: documentsUrl).unwrap()
        try db.execute(
            sql: """
            INSERT INTO entry (path, title, body, modified, size)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(path) DO UPDATE SET
                title=excluded.title,
                body=excluded.body,
                modified=excluded.modified,
                size=excluded.size
            """,
            parameters: [
                .text(path),
                .text(title),
                .text(content),
                .date(modified),
                .integer(size)
            ]
        )
    }
    
    /// Write document syncronously by reading it off of file system
    private func writeDocumentToDatabase(_ url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let title = Subtext.getTitle(markup: content)
        let attributes = try FileFingerprint.Attributes.init(url: url).unwrap()
        try writeDocumentToDatabase(
            url: url,
            title: title,
            content: content,
            modified: attributes.modified,
            size: attributes.size
        )
    }
    
    /// Write a document to the file system, and to the database
    func writeDocumentAsync(
        url: URL,
        title: String,
        content: String
    ) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try content.write(to: url, atomically: true, encoding: .utf8)
            // Re-read size and file modified from file system to make sure
            // what we store is exactly equal to file system.
            let attributes = try FileFingerprint.Attributes(url: url).unwrap()
            try writeDocumentToDatabase(
                url: url,
                title: title,
                content: content,
                modified: attributes.modified,
                size: attributes.size
            )
        }
    }
    
    private func deleteDocumentFromDatabase(_ url: URL) throws {
        try db.execute(
            sql: """
            DELETE FROM entry WHERE path = ?
            """,
            parameters: [
                .text(url.lastPathComponent)
            ]
        )
    }

    /// Remove document from file system and database
    func deleteDocumentAsync(_ url: URL) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try fileManager.removeItem(at: url)
            try deleteDocumentFromDatabase(url)
        }
    }

    func searchSuggestionsForZeroQuery() -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            let threads = try db.execute(
                sql: """
                SELECT path, title
                FROM entry_search
                ORDER BY modified DESC
                LIMIT 4
                """
            ).compactMap({ row in
                try Suggestion.entry(
                    url: URL(
                        fileURLWithPath: row.get(0).unwrap(),
                        relativeTo: documentsUrl
                    ),
                    title: row.get(1).unwrap()
                )
            })

            let topSearches = try db.execute(
                sql: """
                SELECT query, count(query) AS hits
                FROM search_history
                GROUP BY query
                ORDER BY hits DESC
                LIMIT 4
                """
            ).compactMap({ row in
                try Suggestion.query(row.get(0).unwrap())
            })
            
            let suggestions = topSearches + threads
            
            return suggestions
        })
    }

    func searchSuggestionsForQuery(
        _ query: String
    ) -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            guard !query.isWhitespace else {
                return []
            }
            
            let threads = try db.execute(
                sql: """
                SELECT path, title
                FROM entry_search
                WHERE entry_search.title MATCH ?
                ORDER BY rank
                LIMIT 3
                """,
                parameters: [
                    SQLite3Connection.Value.prefixQueryFTS5(query)
                ]
            ).compactMap({ row in
                try Suggestion.entry(
                    url: URL(
                        fileURLWithPath: row.get(0).unwrap(),
                        relativeTo: documentsUrl
                    ),
                    title: row.get(1).unwrap()
                )
            })

            let recentMatchingSearches = try db.execute(
                sql: """
                SELECT DISTINCT query
                FROM search_history
                WHERE query LIKE ?
                ORDER BY created DESC
                LIMIT 3
                """,
                parameters: [
                    SQLite3Connection.Value.prefixQueryLike(query)
                ]
            ).compactMap({ row in
                try Suggestion.query(row.get(0).unwrap())
            })
            
            let verbatimQuerySuggestion = Suggestion.query(query)
            let verbatimCreateSuggestion = Suggestion.create(query)

            return (
                [verbatimQuerySuggestion] +
                recentMatchingSearches +
                threads +
                [verbatimCreateSuggestion]
            )
        })
    }
    
    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchSuggestions(
        _ query: String
    ) -> AnyPublisher<[Suggestion], Error> {
        if query.isWhitespace {
            return searchSuggestionsForZeroQuery()
        } else {
            return searchSuggestionsForQuery(query)
        }
    }

    /// Fetch title suggestions
    /// Currently, this does the same thing as `suggest`, but in future we may differentiate their
    /// behavior.
    func searchTitleSuggestions(
        _ query: String
    ) -> AnyPublisher<[Suggestion], Error> {
        return searchSuggestions(query)
    }

    func search(query: String) -> AnyPublisher<[TextDocument], Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            guard !query.isWhitespace else {
                return []
            }

            // Log search in database
            // TODO if I execute this before the query, it never commits to db.
            // Why? Need to investigate.
            // Wrapping the whole thing in a commit solves the issue.
            // We should figure out how to do what Python does
            // (implicit transaction)
            try db.execute(
                sql: """
                INSERT INTO search_history (id, query)
                VALUES (?, ?);
                """,
                parameters: [
                    .text(UUID().uuidString),
                    .text(query),
                ]
            )

            let docs: [TextDocument] = try db.execute(
                sql: """
                SELECT path, body
                FROM entry_search
                WHERE entry_search MATCH ?
                ORDER BY rank
                LIMIT 25
                """,
                parameters: [
                    .queryFTS5(query)
                ]
            ).map({ row in
                let path: String = try row.get(0).unwrap()
                let content: String = try row.get(1).unwrap()
                let url = documentsUrl.appendingPathComponent(path)
                return TextDocument(
                    url: url,
                    content: content
                )
            })
            
            return docs
        })
    }
}
