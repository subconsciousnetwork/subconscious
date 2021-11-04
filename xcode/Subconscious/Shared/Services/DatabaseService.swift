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

    /// Helper function for generating draft URLs
    func findUniqueURL(name: String) -> URL {
        Slashlink.findUniqueURL(
            at: documentUrl,
            name: name,
            ext: "subtext"
        )
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
                sql: "SELECT slug, modified, size FROM entry"
            ).map({ row in
                FileFingerprint(
                    url: documentUrl.appendingFilename(
                        name: try row.get(0).unwrap(),
                        ext: "subtext"
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
        entry: SubtextFile,
        modified: Date,
        size: Int
    ) throws {
        try database.execute(
            sql: """
            INSERT INTO entry (slug, title, body, modified, size)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(slug) DO UPDATE SET
                title=excluded.title,
                body=excluded.body,
                modified=excluded.modified,
                size=excluded.size
            """,
            parameters: [
                .text(entry.slug),
                .text(entry.title),
                .text(entry.content),
                .date(modified),
                .integer(size)
            ]
        )
    }

    private func writeEntryToDatabase(url: URL) throws {
        let entry = try SubtextFile(url: url)
        let fingerprint = try FileFingerprint.Attributes(url: url).unwrap()
        return try writeEntryToDatabase(
            entry: entry,
            modified: fingerprint.modifiedDate,
            size: fingerprint.size
        )
    }

    func writeEntry(entry: SubtextFile) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            // Write contents to file
            try entry.write()
            // Read fingerprint after writing to get updated time
            let fingerprint = try FileFingerprint.Attributes(
                url: entry.url
            ).unwrap()
            return try writeEntryToDatabase(
                entry: entry,
                modified: fingerprint.modifiedDate,
                size: fingerprint.size
            )
        }
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

    private func searchSuggestionsForZeroQuery() throws -> [Suggestion] {
        let results: [Stub] = try database.execute(
            sql: """
            SELECT slug, substr(body, 1, 560)
            FROM entry
            ORDER BY modified DESC
            LIMIT 5
            """
        ).compactMap({ row in
            if
                let excerpt: String = row.get(1),
                let slug: String = row.get(0)
            {
                return Stub(
                    title: Subtext(markup: excerpt).title(),
                    slug: slug
                )
            }
            return nil
        })

        let queries: [Stub] = try database.execute(
            sql: """
            SELECT DISTINCT search_history.query
            FROM search_history
            ORDER BY search_history.created DESC
            LIMIT 5
            """
        ).compactMap({ row in
            if let title: String = row.get(0) {
                return Stub(title: title)
            }
            return nil
        })

        var suggestions: [Suggestion] = []
        suggestions.append(contentsOf: results.map(Suggestion.entry))
        suggestions.append(contentsOf: queries.map(Suggestion.search))
        return suggestions
    }

    private func searchSuggestionsForQuery(
        query: String
    ) throws -> [Suggestion] {
        guard !query.isWhitespace else {
            return []
        }

        // Select the first 560 characters of the body.
        // We'll use this excerpted text to derive a title.
        let results: [Stub] = try database.execute(
            sql: """
            SELECT slug, substr(body, 1, 560)
            FROM entry_search
            WHERE entry_search MATCH ?
            ORDER BY rank
            LIMIT 5
            """,
            parameters: [
                .prefixQueryFTS5(query)
            ]
        ).compactMap({ row in
            if
                let excerpt: String = row.get(1),
                let slug: String = row.get(0)
            {
                return Stub(
                    title: Subtext(markup: excerpt).title(),
                    slug: slug
                )
            }
            return nil
        })

        let resultSlugs = Set(results.map(\.slug))

        let queries: [Stub] = try database.execute(
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
            if let title: String = row.get(0) {
                return Stub(title: title)
            }
            return nil
        }).filter({ stub in
            !resultSlugs.contains(stub.slug)
        })

        var suggestions: [Suggestion] = []
        let slug = Slashlink.slugify(query)
        if !resultSlugs.contains(slug) {
            suggestions.append(
                .search(
                    Stub(title: query)
                )
            )
        }
        suggestions.append(contentsOf: results.map(Suggestion.entry))
        suggestions.append(contentsOf: queries.map(Suggestion.search))
        return suggestions
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
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Log a search query in search history db
    func insertSearchHistory(query: String) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
            guard !query.isWhitespace else {
                return
            }

            // Log search in database, along with number of hits
            try database.execute(
                sql: """
                INSERT INTO search_history (id, query)
                VALUES (?, ?);
                """,
                parameters: [
                    .text(UUID().uuidString),
                    .text(query)
                ]
            )
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func getEntry(
        slug: String
    ) -> SubtextFile? {
        try? SubtextFile(
            url: documentUrl.appendingFilename(name: slug, ext: "subtext")
        )
    }

    /// Get entry and backlinks from slug
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a clean slug.
    func search(
        query: String,
        slug: String
    ) -> AnyPublisher<ResultSet, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            guard !slug.isWhitespace else {
                return ResultSet()
            }

            let backlinks: [SubtextFile] = try database.execute(
                sql: """
                SELECT slug
                FROM entry_search
                WHERE entry_search.body MATCH ?
                ORDER BY rank
                LIMIT 200
                """,
                parameters: [
                    .queryFTS5(slug)
                ]
            ).compactMap({ row in
                if let matchSlug: String = row.get(0) {
                    if matchSlug != slug {
                        return getEntry(slug: matchSlug)
                    }
                }
                return nil
            })

            let entry = getEntry(slug: slug)

            return ResultSet(
                query: query,
                slug: slug,
                entry: entry,
                backlinks: backlinks
            )
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Search entries by query string
    ///
    /// Note that as an opimization, this method reads the cached contents of the file from DB,
    /// rather than from file (source of truth). This means file contents may be slightly out-of-date.
    /// For up-to-date file contents, read from the file instead.
    ///
    /// Returns an array of SubtextFile objects.
    func suggestEntries(
        query: String,
        limit: Int = 100
    ) -> AnyPublisher<[SubtextFile], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            guard !query.isWhitespace else {
                return []
            }
            return try database.execute(
                sql: """
                SELECT slug, body
                FROM entry_search
                WHERE entry_search MATCH ?
                ORDER BY rank
                LIMIT ?
                """,
                parameters: [
                    .prefixQueryFTS5(query),
                    .integer(limit)
                ]
            ).compactMap({ row in
                if
                    let slug: String = row.get(0),
                    let body: String = row.get(1)
                {
                    return SubtextFile(
                        url: documentUrl.appendingFilename(
                            name: slug,
                            ext: "subtext"
                        ),
                        content: body
                    )
                }
                return nil
            })
        }
    }
}
