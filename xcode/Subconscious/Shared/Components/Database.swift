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
    /// An action that results in no operation
    /// Useful for swallowing success conditions that are the result of an effect
    case noop
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
    case rebuildFailure(message: String)
    /// Sync files with database
    case sync
    case syncSuccess(_ changes: [FileSync.Change])
    case syncFailure(message: String)
    /// Perform a search with query string
    case search(_ query: String)
    case searchSuccess([EntryFile])
    case searchFailure(message: String, query: String)
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
    case .noop:
        return Empty().eraseToAnyPublisher()
    case .setup:
        state.state = .setup
        return environment.migrateDatabase()
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
        return environment.deleteDatabase()
            .flatMap(environment.migrateDatabase)
            .map({ success in DatabaseAction.setupSuccess(success) })
            .catch({ error in
                Just(.rebuildFailure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .rebuildFailure(let message):
        environment.logger.critical(
            """
            Failed to rebuild database.
            
            Error:
            \(message)
            """
        )
    case .sync:
        environment.logger.log("File sync started")
        return environment.syncDatabase()
            .map({ changes in .syncSuccess(changes) })
            .catch({ error in
                Just(.syncFailure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .syncSuccess(let changes):
        environment.logger.log(
            """
            File sync finished
            
            Changes:
            \(changes)
            """
        )
    case .syncFailure(let message):
        environment.logger.warning(
            """
            File sync failed.
            
            Error:
            \(message)
            """
        )
    case .search(let query):
        return environment.search(query: query)
            .map({ results in .searchSuccess(results) })
            .catch({ error in
                Just(
                    .searchFailure(
                        message: error.localizedDescription,
                        query: query
                    )
                )
            })
            .eraseToAnyPublisher()
    case .searchSuccess:
        environment.logger.debug(
            "DatabaseAction.searchSuccess should be handled by parent component"
        )
    case .searchFailure(let message, let query):
        environment.logger.warning(
            """
            Search failed for: \(query)
            
            Error:
            \(message)
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: Environment
struct DatabaseEnvironment {
    private let db: SQLite3ConnectionManager

    let logger = Logger(
        subsystem: "com.subconscious.Subconscious",
        category: "database"
    )
    let fileManager = FileManager.default
    let documentsUrl: URL
    let migrations: SQLite3Migrations

    init(
        databaseUrl: URL,
        documentsUrl: URL,
        migrations: SQLite3Migrations
    ) {
        self.db = SQLite3ConnectionManager(
            url: databaseUrl,
            mode: .readwrite
        )
        self.documentsUrl = documentsUrl
        self.migrations = migrations
    }

    func migrateDatabase() ->
        Future<SQLite3Migrations.MigrationSuccess, Error> {
        Future({ promise in
            DispatchQueue.global(qos: .background).async {
                do {
                    let database = try self.db.connection()
                    let success = try migrations.migrate(database: database)
                    promise(.success(success))
                } catch {
                    promise(.failure(error))
                }
            }
        })
    }

    func deleteDatabase() -> AnyPublisher<Void, Error> {
        CombineUtilities.async(execute: {
            logger.notice("Deleting database")
            do {
                db.close()
                try fileManager.removeItem(at: db.url)
                logger.notice("Deleted database")
            } catch {
                logger.warning("Failed to delete database: \(error.localizedDescription)")
                throw error
            }
        })
    }

    func syncDatabase() -> AnyPublisher<[FileSync.Change], Error> {
        CombineUtilities.async(qos: .utility) {
            let fileUrls = try fileManager.contentsOfDirectory(
                at: documentsUrl,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ).withPathExtension("subtext")

            // Left = Leader (files)
            let left = try FileSync.readFileFingerprints(urls: fileUrls)

            // Right = Follower (search index)
            let right = try db.connection().execute(
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
            ).filter({ change in change.status != .same })
            
            for change in changes {
                switch change.status {
                // .leftOnly = create.
                // .leftNewer = update.
                // .rightNewer = Follower shouldn't be ahead.
                //               Leader wins.
                // .conflict. Leader wins.
                case .leftOnly, .leftNewer, .rightNewer, .conflict:
                    if let left = change.left {
                        try writeEntryToDatabase(left.url)
                    }
                // .rightOnly = delete. Remove from search index
                case .rightOnly:
                    if let right = change.right {
                        try deleteEntryFromDatabase(right.url)
                    }
                // .same = no change. Do nothing.
                case .same:
                    break
                }
            }
            return changes
        }
    }

    func readEntry(url: URL) throws -> EntryFile {
        try EntryFile(url: url)
    }

    func readEntry(url: URL) -> AnyPublisher<EntryFile, Error> {
        Result(catching: {
            try readEntry(url: url)
        }).publisher.eraseToAnyPublisher()
    }
    
    /// Write entry syncronously
    private func writeEntryToDatabase(
        fileWrapper: EntryFile,
        attributes: FileFingerprint.Attributes
    ) throws {
        // Must store relative path, since absolute path of user documents
        // directory can be changed by system.
        let path = try fileWrapper.url.relativizingPath(
            relativeTo: documentsUrl
        ).unwrap()

        try db.connection().execute(
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
                .text(fileWrapper.entry.title),
                .text(fileWrapper.entry.content),
                .date(attributes.modifiedDate),
                .integer(attributes.size)
            ]
        )
    }
    
    /// Write entry syncronously by reading it off of file system
    private func writeEntryToDatabase(_ url: URL) throws {
        let wrapper = try EntryFile(url: url)
        let attributes = try FileFingerprint.Attributes.init(url: url).unwrap()
        try writeEntryToDatabase(
            fileWrapper: wrapper,
            attributes: attributes
        )
    }

    /// Create a new entry on the file system, and write to the database
    func createEntry(_ entry: Entry) -> AnyPublisher<EntryFile, Error> {
        CombineUtilities.async {
            let fileWrapper = try EntryFile(entry: entry).unwrap()
            return try writeEntry(fileWrapper)
        }
    }

    func writeEntry(
        _ fileWrapper: EntryFile
    ) throws -> EntryFile {
        try fileWrapper.write()
        // Re-read size and file modified from file system to make sure
        // what we store is exactly equal to file system.
        let attributes = try FileFingerprint.Attributes(
            url: fileWrapper.url
        ).unwrap()
        try writeEntryToDatabase(
            fileWrapper: fileWrapper,
            attributes: attributes
        )
        return fileWrapper
    }
    
    /// Write an entry to the file system, and to the database
    func writeEntry(
        _ fileWrapper: EntryFile
    ) -> AnyPublisher<EntryFile, Error> {
        CombineUtilities.async {
            try writeEntry(fileWrapper)
        }
    }
    
    private func deleteEntryFromDatabase(_ url: URL) throws {
        try db.connection().execute(
            sql: """
            DELETE FROM entry WHERE path = ?
            """,
            parameters: [
                .text(url.lastPathComponent)
            ]
        )
    }

    /// Remove entry from file system and database
    func deleteEntry(_ url: URL) -> AnyPublisher<URL, Error> {
        CombineUtilities.async {
            try fileManager.removeItem(at: url)
            try deleteEntryFromDatabase(url)
            return url
        }
    }

    /// List recent entries
    func selectRecent() throws -> [EntryFile] {
        try db.connection().execute(
            sql: """
            SELECT path, body FROM entry
            ORDER BY modified DESC
            LIMIT 25
            """
        ).map({ row in
            EntryFile(
                url: URL(
                    fileURLWithPath: try row.get(0).unwrap(),
                    relativeTo: documentsUrl
                ),
                content: try row.get(1).unwrap()
            )
        })
    }

    func selectRecent() -> AnyPublisher<[EntryFile], Error> {
        CombineUtilities.async(qos: .userInitiated, execute: selectRecent)
    }

    func searchSuggestionsForZeroQuery() -> AnyPublisher<Suggestions, Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            let searches = try db.connection().execute(
                sql: """
                SELECT query FROM (
                    SELECT title AS query
                    FROM entry_search
                    ORDER BY modified DESC
                    LIMIT 4
                )
                UNION
                SELECT query FROM (
                    SELECT query, count(query) AS queries
                    FROM search_history
                    WHERE hits > 0
                    GROUP BY query
                    ORDER BY queries DESC
                    LIMIT 4
                )
                """
            ).compactMap({ row in
                try SearchSuggestion(query: row.get(0).unwrap())
            })

            let recent = try db.connection().execute(
                sql: """
                SELECT path, title
                FROM entry_search
                ORDER BY modified DESC
                LIMIT 3
                """
            ).compactMap({ row in
                try ActionSuggestion.edit(
                    url: URL(
                        fileURLWithPath: row.get(0).unwrap(),
                        relativeTo: documentsUrl
                    ),
                    title: row.get(1).unwrap()
                )
            })

            return Suggestions(
                searches: searches,
                actions: recent
            )
        })
    }

    func searchSuggestionsForQuery(
        _ query: String
    ) -> AnyPublisher<Suggestions, Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            guard !query.isWhitespace else {
                return Suggestions()
            }

            let entries = try db.connection().execute(
                sql: """
                SELECT DISTINCT path, title AS query
                FROM entry_search
                WHERE entry_search.title MATCH ?
                ORDER BY rank
                LIMIT 5
                """,
                parameters: [
                    SQLite3Connection.Value.queryFTS5(query)
                ]
            )

            let history = try db.connection().execute(
                sql: """
                SELECT DISTINCT query
                FROM search_history
                WHERE query LIKE ?
                ORDER BY created DESC
                LIMIT 5
                """,
                parameters: [
                    SQLite3Connection.Value.prefixQueryLike(query)
                ]
            )

            let literalSearches = [SearchSuggestion(query: query)]

            let titleSearches: [SearchSuggestion] = entries.compactMap({ row in
                if let text: String = row.get(1) {
                    return SearchSuggestion(query: text)
                }
                return nil
            })

            let historySearches: [SearchSuggestion] = history.compactMap({ row in
                if let text: String = row.get(0) {
                    return SearchSuggestion(query: text)
                }
                return nil
            })

            let searches = Array(
                literalSearches
                    .appending(contentsOf: titleSearches)
                    .appending(contentsOf: historySearches)
                    .unique()
                    .prefix(6)
            )

            let editActions: [ActionSuggestion] = entries
                .prefix(3)
                .compactMap({ row in
                    if
                        let path: String = row.get(0),
                        let text: String = row.get(1)
                    {
                        return ActionSuggestion.edit(
                            url: URL(
                                fileURLWithPath: path, relativeTo: documentsUrl
                            ),
                            title: text
                        )
                    }
                    return nil
                })

            let createActions = [
                ActionSuggestion.create(query)
            ]

            let actions = Array(
                editActions
                    .appending(contentsOf: createActions)
                    .unique()
            )

            return Suggestions(
                searches: searches,
                actions: actions
            )
        })
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchSuggestions(
        _ query: String
    ) -> AnyPublisher<Suggestions, Error> {
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
    ) -> AnyPublisher<Suggestions, Error> {
        return searchSuggestions(query)
    }

    /// Log a search query in search history db
    func insertSearchHistory(query: String) -> AnyPublisher<String, Error> {
        CombineUtilities.async(qos: .background, execute: {
            guard !query.isWhitespace else {
                return query
            }

            // Log search in database, along with number of hits
            try db.connection().execute(
                sql: """
                INSERT INTO search_history (id, query, hits)
                VALUES (?, ?, (
                    SELECT count(path)
                    FROM entry_search
                    WHERE entry_search MATCH ?
                ));
                """,
                parameters: [
                    .text(UUID().uuidString),
                    .text(query),
                    .queryFTS5(query),
                ]
            )

            return query
        })
    }

    func findEntriesByTitles(_ titles: [String]) throws -> [EntryFile] {
        let titlesJSON = try SQLite3Connection.Value.json(titles).unwrap()
        return try db.connection().execute(
            sql: """
            SELECT entry.path, entry.body
            FROM entry
            JOIN json_each(?) AS title
            ON entry.title = title.value
            """,
            parameters: [
                titlesJSON
            ]
        ).map({ row in
            let path: String = try row.get(0).unwrap()
            let content: String = try row.get(1).unwrap()
            return EntryFile(
                url: URL(fileURLWithPath: path, relativeTo: documentsUrl),
                content: content
            )
        })
    }

    func search(query: String) -> AnyPublisher<[EntryFile], Error> {
        CombineUtilities.async(qos: .userInitiated, execute: {
            guard !query.isWhitespace else {
                return []
            }

            let docs: [EntryFile] = try db.connection().execute(
                sql: """
                SELECT path, body
                FROM entry_search
                WHERE entry_search MATCH ?
                AND rank = 'bm25(0.0, 10.0, 1.0, 0.0, 0.0)'
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
                return EntryFile(
                    url: url,
                    content: content
                )
            })

            let wikilinks = docs.flatMap({ entryFile in
                entryFile.entry.content.wikilinks()
            })

            let related = try findEntriesByTitles(wikilinks).toDictionary(key: { entryFile in
                entryFile.entry.title
            })

            return docs
        })
    }
}
