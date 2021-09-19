//
//  DatabaseService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//
//  Handles reading from, writing to, and migrating database.

import Foundation
import OrderedCollections

struct DatabaseService {
    private var documentsURL: URL
    private var databaseURL: URL
    private var database: SQLite3Database
    private var migrations: SQLite3Migrations

    init(
        documentsURL: URL,
        databaseURL: URL,
        migrations: SQLite3Migrations
    ) {
        self.documentsURL = documentsURL
        self.databaseURL = databaseURL
        self.database = .init(
            path: databaseURL.absoluteString,
            mode: .readwrite
        )
        self.migrations = migrations
    }

    /// Close database connection and delete database file
    func delete() throws {
        database.close()
        try FileManager.default.removeItem(at: databaseURL)
    }

    func migrate() throws -> SQLite3Migrations.MigrationSuccess {
        try migrations.migrate(database: database)
    }

    /// Write entry syncronously
    mutating func writeEntry(
        path: String,
        title: String,
        body: String,
        modified: Date,
        size: Int
    ) throws {
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
                .text(title),
                .text(body),
                .date(modified),
                .integer(size)
            ]
        )
    }

    private func deleteEntry(path: String) throws {
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
    
    func searchSuggestionsForZeroQuery() throws -> [Suggestion] {
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

    func searchSuggestionsForQuery(query: String) throws -> [Suggestion] {
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
    ) throws -> [Suggestion] {
        if query.isWhitespace {
            return try searchSuggestionsForZeroQuery()
        } else {
            return try searchSuggestionsForQuery(query: query)
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
                url: URL(fileURLWithPath: path, relativeTo: documentsURL),
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
            let url = documentsURL.appendingPathComponent(path)
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
