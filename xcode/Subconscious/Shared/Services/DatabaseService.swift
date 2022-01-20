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
                        try writeEntryToDatabase(slug: left.url.toSlug())
                    }
                // .rightOnly = delete. Remove from search index
                case .rightOnly:
                    if let right = change.right {
                        let slug = right.url.toSlug()
                        try deleteEntryFromDatabase(slug: slug)
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

    private func writeEntryToDatabase(slug: Slug) throws {
        let entry = try SubtextFile(slug: slug, directory: documentUrl).unwrap()
        let fingerprint = try FileFingerprint.Attributes(
            url: entry.url(directory: documentUrl)
        ).unwrap()
        return try writeEntryToDatabase(
            entry: entry,
            modified: fingerprint.modifiedDate,
            size: fingerprint.size
        )
    }

    func writeEntry(entry: SubtextFile) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            // Write contents to file
            try entry.write(directory: documentUrl)
            // Read fingerprint after writing to get updated time
            let fingerprint = try FileFingerprint.Attributes(
                url: entry.url(directory: documentUrl)
            ).unwrap()
            return try writeEntryToDatabase(
                entry: entry,
                modified: fingerprint.modifiedDate,
                size: fingerprint.size
            )
        }
    }

    /// Delete entry from database
    private func deleteEntryFromDatabase(slug: Slug) throws {
        try database.execute(
            sql: """
            DELETE FROM entry WHERE slug = ?
            """,
            parameters: [
                .text(slug)
            ]
        )
    }

    /// Delete entry from file system
    private func deleteEntryFile(slug: Slug) throws {
        let url = documentUrl.appendingFilename(name: slug, ext: "subtext")
        try FileManager.default.removeItem(at: url)
    }

    /// Delete entry from file system and database
    func deleteEntry(slug: Slug) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .background) {
            try deleteEntryFile(slug: slug)
            try deleteEntryFromDatabase(slug: slug)
        }
    }

    /// Rename or merge entry.
    /// Updates both database and file system.
    func renameEntry(from: Slug, to: Slug) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            print("TODO implement renameEntry")
            return
        }
    }

    /// List recent entries
    func listRecentEntries() -> AnyPublisher<[EntryStub], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            // Use stale body content from db. It's faster, and these
            // are read-only teaser views.
            try database.execute(
                sql: """
                SELECT slug, title, body
                FROM entry_search
                ORDER BY modified DESC
                LIMIT 1000
                """
            ).compactMap({ row in
                if
                    let slug: String = row.get(0),
                    let title: String = row.get(1),
                    let content: String = row.get(2)
                {
                    let subtext = Subtext(markup: content)
                    return EntryStub(
                        slug: slug,
                        title: title,
                        excerpt: subtext.excerpt()
                    )
                }
                return nil
            })
        }
    }

    private func searchSuggestionsForZeroQuery(
    ) throws -> OrderedDictionary<String, Suggestion> {
        var suggestions: OrderedDictionary<String, Suggestion> = [:]

        let entries: [EntryLink] = try database.execute(
            sql: """
            SELECT slug, title
            FROM entry
            ORDER BY modified DESC
            LIMIT 5
            """
        )
        .compactMap({ row in
            if
                let slug: String = row.get(0),
                let title: String = row.get(1)
            {
                return EntryLink(
                    slug: slug,
                    title: title
                )
            }
            return nil
        })

        for entry in entries {
            suggestions.updateValue(.entry(entry), forKey: entry.slug)
        }

        let queries: [EntryLink] = try database.execute(
            sql: """
            SELECT DISTINCT search_history.query
            FROM search_history
            ORDER BY search_history.created DESC
            LIMIT 5
            """
        )
        .compactMap({ row in
            if let title: String = row.get(0) {
                return EntryLink(title: title)
            }
            return nil
        })

        // Append queries, except those which would have the same slug as
        // an existing entry.
        for query in queries {
            if suggestions[query.slug] == nil {
                suggestions.updateValue(.search(query), forKey: query.slug)
            }
        }

        return suggestions
    }

    private func searchSuggestionsForQuery(
        query: String
    ) throws -> OrderedDictionary<String, Suggestion> {
        guard !query.isWhitespace else {
            return OrderedDictionary<String, Suggestion>()
        }

        var suggestions: OrderedDictionary<String, Suggestion> = [:]

        /// Create a suggestion for the literal query
        let querySlug = query.slugifyString()
        suggestions[querySlug] = .search(
            EntryLink(title: query)
        )

        let entries: [EntryLink] = try database.execute(
            sql: """
            SELECT slug, title
            FROM entry_search
            WHERE entry_search MATCH ?
            ORDER BY rank
            LIMIT 5
            """,
            parameters: [
                .prefixQueryFTS5(query)
            ]
        )
        .compactMap({ row in
            if
                let slug: String = row.get(0),
                let title: String = row.get(1)
            {
                return EntryLink(
                    slug: slug,
                    title: title
                )
            }
            return nil
        })

        // Insert entries into suggestions.
        // If literal query and an entry have the same slug,
        // entry will overwrite query.
        for entry in entries {
            suggestions.updateValue(.entry(entry), forKey: entry.slug)
        }

        // Append queries, except those which would have the same slug as
        // an existing entry.
        let queries: [EntryLink] = try database.execute(
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
        )
        .compactMap({ row in
            if let title: String = row.get(0) {
                return EntryLink(title: title)
            }
            return nil
        })

        for query in queries {
            if suggestions[query.slug] == nil {
                suggestions.updateValue(.search(query), forKey: query.slug)
            }
        }

        return suggestions
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchSuggestions(
        query: String
    ) -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            if query.isWhitespace {
                let suggestions = try searchSuggestionsForZeroQuery()
                return Array(suggestions.values)
            } else {
                let suggestions = try searchSuggestionsForQuery(query: query)
                return Array(suggestions.values)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Given a query and a `current` slug, produce an array of suggestions
    /// for renaming the note.
    func searchRenameSuggestions(
        query: String,
        current: Slug?
    ) -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            guard !query.isWhitespace else {
                return []
            }

            var suggestions: OrderedDictionary<Slug, Suggestion> = [:]

            let querySuggestion = Suggestion.search(EntryLink(title: query))
            //  If slug of literal query would be different from current slug
            //  make this the first suggestion.
            if querySuggestion.stub.slug != current {
                suggestions[querySuggestion.id] = querySuggestion
            }

            let searches: [EntryLink] = try database.execute(
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
            )
            .compactMap({ row in
                if let title: String = row.get(0) {
                    return EntryLink(title: title)
                }
                return nil
            })

            for search in searches {
                //  Do not suggest current slug
                if search.slug != current {
                    suggestions.updateValue(.search(search), forKey: search.id)
                }
            }

            let entries: [EntryLink] = try database.execute(
                sql: """
                SELECT slug, title
                FROM entry_search
                WHERE entry_search MATCH ?
                ORDER BY rank
                LIMIT 5
                """,
                parameters: [
                    .prefixQueryFTS5(query)
                ]
            )
            .compactMap({ row in
                if
                    let slug: String = row.get(0),
                    let title: String = row.get(1)
                {
                    return EntryLink(
                        slug: slug,
                        title: title
                    )
                }
                return nil
            })

            for entry in entries {
                //  Do not suggest renaming to same name
                if entry.slug != current {
                    suggestions.updateValue(.entry(entry), forKey: entry.id)
                }
            }

            return Array(suggestions.values)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Log a search query in search history db
    func createSearchHistoryItem(query: String) -> AnyPublisher<Void, Error> {
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

    private func readEntry(
        slug: Slug
    ) -> SubtextFile? {
        SubtextFile(
            slug: slug,
            directory: documentUrl
        )
    }

    /// Get entry and backlinks from slug.
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a
    /// clean slug.
    func search(
        query: String,
        slug: Slug
    ) -> AnyPublisher<ResultSet, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            guard !slug.isWhitespace else {
                return ResultSet()
            }

            // Get backlinks.
            // Use content indexed in database, even though it might be stale.
            let backlinks: [EntryStub] = try database.execute(
                sql: """
                SELECT slug, title, body
                FROM entry_search
                WHERE slug != ? AND entry_search.body MATCH ?
                ORDER BY rank
                LIMIT 200
                """,
                parameters: [
                    .text(slug),
                    .queryFTS5(slug)
                ]
            ).compactMap({ row in
                if
                    let slug: String = row.get(0),
                    let title: String = row.get(1),
                    let content: String = row.get(2)
                {
                    let subtext = Subtext(markup: content)
                    return EntryStub(
                        slug: slug,
                        title: title,
                        excerpt: subtext.excerpt()
                    )
                }
                return nil
            })

            // Retreive top entry from file system to ensure it is fresh.
            let entry = readEntry(slug: slug)
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
}
