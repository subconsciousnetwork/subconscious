//
//  DatabaseService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//
//  Handles reading from, writing to, and migrating database.

import Foundation
import Combine
import OrderedCollections

struct DatabaseService {
    enum DatabaseServiceError: Error {
        case pathNotInFilePath
    }

    private var documentUrl: URL
    private var databaseURL: URL
    private var database: SQLite3Database
    private var migrations: SQLite3Migrations

    init(
        documentURL: URL,
        databaseURL: URL,
        migrations: SQLite3Migrations
    ) {
        self.documentUrl = documentURL
        self.databaseURL = databaseURL
        self.database = .init(
            path: databaseURL.absoluteString,
            mode: .readwrite
        )
        self.migrations = migrations
    }

    /// Close database connection and delete database file
    func delete() -> AnyPublisher<Void, Error> {
        CombineUtilities.async(
            qos: .background,
            execute: {
                database.close()
                try FileManager.default.removeItem(at: databaseURL)
            }
        ).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    func migrate() -> AnyPublisher<SQLite3Migrations.MigrationSuccess, Error> {
        CombineUtilities.async(
            qos: .userInitiated,
            execute: {
                try migrations.migrate(database: database)
            }
        ).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    func syncDatabase() -> AnyPublisher<[FileSync.Change], Error> {
        CombineUtilities.async(qos: .utility) {
            let fileUrls = try listEntries()

            // Left = Leader (files)
            let left = try FileSync.readFileFingerprints(urls: fileUrls)

            // Right = Follower (search index)
            let right = try database.execute(
                sql: "SELECT path, modified, size FROM entry"
            ).map({ row  in
                FileFingerprint(
                    url: URL(
                        fileURLWithPath: try row.get(0).unwrap(),
                        relativeTo: documentUrl
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
                        try writeEntryToDatabase(url: left.url)
                    }
                // .rightOnly = delete. Remove from search index
                case .rightOnly:
                    if let right = change.right {
                        try deleteEntryFromDatabase(url: right.url)
                    }
                // .same = no change. Do nothing.
                case .same:
                    break
                }
            }
            return changes
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func listEntries() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: documentUrl,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ).withPathExtension("subtext")
    }

    /// Write entry syncronously
    private func writeEntryToDatabase(
        entry: TextFile,
        fingerprint: FileFingerprint.Attributes
    ) throws {
        let path = try entry.url.relativizingPath(relativeTo: documentUrl)
            .unwrap(or: DatabaseServiceError.pathNotInFilePath)
        try database.execute(
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
                .text(entry.title),
                .text(entry.content),
                .date(fingerprint.modifiedDate),
                .integer(fingerprint.size)
            ]
        )
    }

    private func writeEntryToDatabase(url: URL) throws {
        let entry = try TextFile(url: url)
        let fingerprint = try FileFingerprint.Attributes(url: url).unwrap()
        return try writeEntryToDatabase(
            entry: entry,
            fingerprint: fingerprint
        )
    }
    
    private func deleteEntryFromDatabase(url: URL) throws {
        let path = try url.relativizingPath(relativeTo: documentUrl)
            .unwrap(or: DatabaseServiceError.pathNotInFilePath)
        try database.execute(
            sql: """
            DELETE FROM entry WHERE path = ?
            """,
            parameters: [
                .text(path)
            ]
        )
    }

    private static func collateSuggestions(
        query: String,
        results: [String],
        queries: [String]
    ) -> [Suggestion] {
        let resultPairs = results.map({ string in
            (string.toSlug(), string)
        })

        let queryPairs = queries.map({ string in
            (string.toSlug(), string)
        })

        let resultDict = OrderedDictionary(
            resultPairs,
            uniquingKeysWith: { (first, _) in first }
        )

        let querySlug = query.toSlug()

        var queryDict = OrderedDictionary(
            queryPairs,
            uniquingKeysWith: { (first, _) in first }
        )

        // Remove queries that are also in results
        queryDict.removeKeys(keys: resultDict.keys.elements)
        // Remove query itself. We always place the literal query as the first result.
        queryDict.removeValue(forKey: querySlug)

        // Create a mutable array we can use for suggestions.
        var suggestions: [Suggestion] = []

        // If we have a user query, and the query is not in results,
        // then append it to top.
        if !query.isWhitespace && resultDict[query.toSlug()] == nil {
            suggestions.append(
                .search(query)
            )
        }

        for query in resultDict.values {
            suggestions.append(.entry(query))
        }

        for query in queryDict.values {
            suggestions.append(.search(query))
        }

        return suggestions
    }

    private func searchSuggestionsForZeroQuery() throws -> [Suggestion] {
        let results: [String] = try database.execute(
            sql: """
            SELECT DISTINCT title
            FROM entry_search
            ORDER BY modified DESC
            LIMIT 5
            """
        ).compactMap({ row in row.get(0) })

        let queries: [String] = try database.execute(
            sql: """
            SELECT DISTINCT search_history.query
            FROM search_history
            ORDER BY search_history.created DESC
            LIMIT 5
            """
        ).compactMap({ row in
            row.get(0)
        })

        return Self.collateSuggestions(
            query: "",
            results: results,
            queries: queries
        )
    }

    private func searchSuggestionsForQuery(query: String) throws -> [Suggestion] {
        guard !query.isWhitespace else {
            return []
        }

        let results: [String] = try database.execute(
            sql: """
            SELECT DISTINCT title
            FROM entry_search
            WHERE entry_search.title MATCH ?
            ORDER BY rank
            LIMIT 5
            """,
            parameters: [
                .prefixQueryFTS5(query)
            ]
        ).compactMap({ row in
            row.get(0)
        })

        let queries: [String] = try database.execute(
            sql: """
            SELECT DISTINCT query
            FROM search_history
            WHERE query LIKE ?
            ORDER BY created DESC
            LIMIT 3
            """,
            parameters: [
                .prefixQueryLike(query)
            ]
        ).compactMap({ row in
            row.get(0)
        })

        return Self.collateSuggestions(
            query: query,
            results: results,
            queries: queries
        )
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchSuggestions(
        query: String
    ) -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            if query.isWhitespace {
                return try searchSuggestionsForZeroQuery()
            } else {
                return try searchSuggestionsForQuery(query: query)
            }
        }
    }

    /// Log a search query in search history db
    func insertSearchHistory(query: String) throws {
        guard !query.isWhitespace else {
            return
        }

        // Log search in database, along with number of hits
        try database.execute(
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
    }

    func findEntryByTitle(_ title: String) throws -> TextFile? {
        let results: [TextFile] = try database.execute(
            sql: """
            SELECT entry.path, entry.body
            FROM entry
            WHERE entry.title LIKE ?
            LIMIT 1
            """,
            parameters: [
                .text(title)
            ]
        ).map({ row in
            let path: String = try row.get(0).unwrap()
            let content: String = try row.get(1).unwrap()
            return TextFile(
                url: URL(fileURLWithPath: path, relativeTo: documentUrl),
                content: content
            )
        })
        return results.first
    }

    func search(query: String) throws -> TextFileResults {
        guard !query.isWhitespace else {
            return TextFileResults()
        }

        let matches: [TextFile] = try database.execute(
            sql: """
            SELECT path, body
            FROM entry_search
            WHERE entry_search MATCH ?
            AND rank = 'bm25(0.0, 10.0, 1.0, 0.0, 0.0)'
            ORDER BY rank
            LIMIT 200
            """,
            parameters: [
                .queryFTS5(query)
            ]
        ).map({ row in
            let path: String = try row.get(0).unwrap()
            let content: String = try row.get(1).unwrap()
            let url = documentUrl.appendingPathComponent(path)
            return TextFile(
                url: url,
                content: content
            )
        })

        let entry = try findEntryByTitle(query)

        let backlinks: [TextFile]
        if let entry = entry {
            // If we have an entry, filter it out of the results
            backlinks = matches.filter({ fileEntry in
                fileEntry.id != entry.id
            })
        } else {
            backlinks = matches
        }

        return TextFileResults(
            entry: entry,
            backlinks: backlinks
        )
    }
}
