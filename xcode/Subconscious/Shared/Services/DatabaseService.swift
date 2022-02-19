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
        case invalidSlug(String)
        case notFound
    }

    private var documentURL: URL
    private var databaseURL: URL
    private var database: SQLite3Database
    private var migrations: SQLite3Migrations

    init(
        documentURL: URL,
        databaseURL: URL,
        migrations: SQLite3Migrations
    ) {
        self.documentURL = documentURL
        self.databaseURL = databaseURL
        self.database = .init(
            path: databaseURL.absoluteString,
            mode: .readwrite
        )
        self.migrations = migrations
    }

    /// Helper function for generating draft URLs
    func findUniqueURL(name: String) -> URL? {
        Slashlink.findUniqueURL(
            at: documentURL,
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
        )
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func migrate() -> AnyPublisher<SQLite3Migrations.MigrationSuccess, Error> {
        CombineUtilities.async(
            qos: .userInitiated,
            execute: {
                try migrations.migrate(database: database)
            }
        )
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Sync file system with database.
    /// Note file system is source-of-truth (leader).
    /// Syncing will never delete files on the file system.
    func syncDatabase() -> AnyPublisher<[FileSync.Change], Error> {
        CombineUtilities.async(qos: .utility) {
            // Left = Leader (files)
            let left = try FileSync.readFileFingerprints(
                directory: documentURL,
                ext: "subtext"
            ).unwrap()

            // Right = Follower (search index)
            let right: [FileFingerprint] = try database.execute(
                sql: "SELECT slug, modified, size FROM entry"
            ).compactMap({ row in
                if
                    let slugString: String = row.get(0),
                    let slug = Slug(slugString),
                    let modified: Date = row.get(1),
                    let size: Int = row.get(2)
                {
                    return FileFingerprint(
                        slug: slug,
                        modified: modified,
                        size: size
                    )
                }
                return nil
            })
            
            let changes = FileSync.calcChanges(
                left: left,
                right: right
            ).filter({ change in
                switch change {
                case .same:
                    return false
                default:
                    return true
                }
            })
            
            for change in changes {
                switch change {
                // .leftOnly = create.
                // .leftNewer = update.
                // .rightNewer = Follower shouldn't be ahead.
                //               Leader wins.
                // .conflict. Leader wins.
                case
                    .leftOnly(let left),
                    .leftNewer(let left, _),
                    .rightNewer(let left, _),
                    .conflict(let left, _):
                    try writeEntryToDatabase(slug: left.slug)
                // .rightOnly = delete. Remove from search index
                case .rightOnly(let right):
                    try deleteEntryFromDatabase(slug: right.slug)
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
                .text(entry.slug.description),
                .text(entry.dom.title()),
                .text(entry.content),
                .date(modified),
                .integer(size)
            ]
        )
    }

    private func writeEntryToDatabase(slug: Slug) throws {
        let entry = try SubtextFile(slug: slug, directory: documentURL).unwrap()
        let fingerprint = try FileFingerprint.Attributes(
            url: entry.url(directory: documentURL)
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
            try entry.write(directory: documentURL)
            // Read fingerprint after writing to get updated time
            let fingerprint = try FileFingerprint.Attributes(
                url: entry.url(directory: documentURL)
            ).unwrap()
            return try writeEntryToDatabase(
                entry: entry,
                modified: fingerprint.modifiedDate,
                size: fingerprint.size
            )
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Delete entry from database
    private func deleteEntryFromDatabase(slug: Slug) throws {
        try database.execute(
            sql: """
            DELETE FROM entry WHERE slug = ?
            """,
            parameters: [
                .text(slug.description)
            ]
        )
    }

    /// Delete entry from file system
    private func deleteEntryFile(slug: Slug) throws {
        let url = slug.toURL(directory: documentURL, ext: "subtext")
        try FileManager.default.removeItem(at: url)
    }

    /// Delete entry from file system and database
    func deleteEntry(slug: Slug) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .background) {
            try deleteEntryFile(slug: slug)
            try deleteEntryFromDatabase(slug: slug)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Rename file in file system
    private func moveEntryFile(from: Slug, to: Slug) throws {
        let fromURL = from.toURL(directory: documentURL, ext: "subtext")
        let toURL = to.toURL(directory: documentURL, ext: "subtext")
        try FileManager.default.moveItem(at: fromURL, to: toURL)
    }

    /// Merge two files together
    /// - Appends `from` to `to`
    /// - Writes the combined content to `to`
    /// - Deletes `from`
    private func mergeEntryFile(from: Slug, to: Slug) throws {
        let fromFile = try SubtextFile(
            slug: from,
            directory: documentURL
        )
        .unwrap()

        let toFile = try SubtextFile(
            slug: to,
            directory: documentURL
        )
        .unwrap()
        .append(fromFile.dom)

        //  First write the merged file to "to" location
        try toFile.write(directory: documentURL)
        //  Then remove the file at "from" location.
        //  We delete AFTER writing so that data loss cannot occur in
        //  case of failure.
        try FileManager.default.removeItem(
            at: fromFile.url(directory: documentURL)
        )
    }

    /// Rename or merge entry.
    /// Updates both database and file system.
    func renameOrMergeEntry(
        from: Slug,
        to: Slug
    ) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            // Succeed and do nothing if `from` and `to` are the same.
            guard from != to else {
                return
            }

            let toURL = to.toURL(directory: documentURL, ext: "subtext")

            //  If file already exists, perform a merge.
            //  Otherwise, perform a rename.
            //  NOTE: It's important to use `.path` and not `.absolutePath`.
            //  For whatever reason, `.fileExists` will not find the file
            //  at its `.absolutePath`.
            //  2022-01-21 Gordon Brander
            if FileManager.default.fileExists(atPath: toURL.path) {
                try mergeEntryFile(from: from, to: to)
                try writeEntryToDatabase(slug: to)
                try deleteEntryFromDatabase(slug: from)
                return
            } else {
                try moveEntryFile(from: from, to: to)
                try writeEntryToDatabase(slug: to)
                try deleteEntryFromDatabase(slug: from)
                return
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// List recent entries
    func listRecentEntries() -> AnyPublisher<[EntryStub], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            // Use stale body content from db. It's faster, and these
            // are read-only teaser views.
            try database.execute(
                sql: """
                SELECT slug, body
                FROM entry_search
                ORDER BY modified DESC
                LIMIT 1000
                """
            ).compactMap({ row in
                if
                    let slugString: String = row.get(0),
                    let slug = Slug(slugString),
                    let content: String = row.get(1)
                {
                    let summary = Subtext(markup: content).summarize()
                    return EntryStub(
                        slug: slug,
                        title: summary.title ?? "",
                        excerpt: summary.excerpt ?? ""
                    )
                }
                return nil
            })
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func searchSuggestionsForZeroQuery() throws -> [Suggestion] {
        var suggestions = try database.execute(
            sql: """
            SELECT slug, title
            FROM entry
            ORDER BY modified DESC
            LIMIT 25
            """
        )
        .compactMap({ row in
            if
                let slugString: String = row.get(0),
                let slug = Slug(slugString),
                let title: String = row.get(1)
            {
                return EntryLink(
                    slug: slug,
                    title: title
                )
            }
            return nil
        })
        .map({ link in
            Suggestion.entry(link)
        })

        let dateTimeFormatter = ISO8601DateFormatter.internet()
        let dateTime = dateTimeFormatter.string(from: Date.now)
        let dateFormatter = DateFormatter.yyyymmdd()
        let date = dateFormatter.string(from: Date.now)

        var special: [Suggestion] = []

        // Insert scratch
        if let slug = Slug("log/\(dateTime)") {
            special.append(
                .journal(
                    EntryLink(
                        slug: slug,
                        title: date
                    )
                )
            )
        }

        // Insert an option to load a random idea if there are any ideas.
        if suggestions.count > 2 {
            special.append(.random)
        }

        special.append(contentsOf: suggestions)

        return special
    }

    private func searchSuggestionsForQuery(
        query: String
    ) throws -> [Suggestion] {
        // If slug is invalid, return empty suggestions
        guard
            let querySlug = Slug(query),
            let queryEntryLink = EntryLink(title: query)
        else {
            return []
        }

        var suggestions: OrderedDictionary<Slug, Suggestion> = [:]

        // Create a suggestion for the literal query
        suggestions[querySlug] = .search(queryEntryLink)

        let entries: [EntryLink] = try database.execute(
            sql: """
            SELECT slug, title
            FROM entry_search
            WHERE entry_search MATCH ?
            ORDER BY rank
            LIMIT 25
            """,
            parameters: [
                .prefixQueryFTS5(query)
            ]
        )
        .compactMap({ row in
            if
                let slugString: String = row.get(0),
                let slug = Slug(slugString),
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

        return Array(suggestions.values)
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

    /// Given a query and a `current` slug, produce an array of suggestions
    /// for renaming the note.
    func searchRenameSuggestions(
        query: String,
        current: Slug?
    ) -> AnyPublisher<[RenameSuggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            guard let queryEntryLink = EntryLink(title: query) else {
                return []
            }

            var suggestions: OrderedDictionary<Slug, RenameSuggestion> = [:]

            //  If slug of literal query would be different from current slug
            //  make this the first suggestion.
            if queryEntryLink.slug != current {
                let querySuggestion = RenameSuggestion.rename(queryEntryLink)
                suggestions.updateValue(
                    querySuggestion,
                    forKey: queryEntryLink.slug
                )
            }

            let entries: [EntryLink] = try database.execute(
                sql: """
                SELECT slug, title
                FROM entry_search
                WHERE entry_search MATCH ?
                ORDER BY rank
                LIMIT 25
                """,
                parameters: [
                    .prefixQueryFTS5(query)
                ]
            )
            .compactMap({ row in
                if
                    let slugString: String = row.get(0),
                    let slug = Slug(slugString),
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
                    suggestions.updateValue(
                        .merge(entry),
                        forKey: entry.slug
                    )
                }
            }
            return Array(suggestions.values)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchLinkSuggestions(
        query: String
    ) -> AnyPublisher<[LinkSuggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            let sluglike = Slug.toSluglikeString(query)
            if sluglike.isEmpty {
                return []
            }

            var suggestions: OrderedDictionary<Slug, LinkSuggestion> = [:]

            // Append literal
            if let literal = EntryLink(title: query) {
                suggestions[literal.slug] = .new(literal)
            }

            let entries: [EntryLink] = try database
                .execute(
                    sql: """
                    SELECT slug, title
                    FROM entry_search
                    WHERE entry_search MATCH ?
                    ORDER BY rank
                    LIMIT 25
                    """,
                    parameters: [
                        .prefixQueryFTS5(sluglike)
                    ]
                )
                .compactMap({ row in
                    if
                        let slugString: String = row.get(0),
                        let slug = Slug(slugString),
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
            directory: documentURL
        )
    }

    /// Get entry and backlinks from slug.
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a
    /// clean slug.
    func readEntryDetail(
        slug: Slug,
        fallback: String
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            // Get backlinks.
            // Use content indexed in database, even though it might be stale.
            let backlinks: [EntryStub] = try database.execute(
                sql: """
                SELECT slug, body
                FROM entry_search
                WHERE slug != ? AND entry_search.body MATCH ?
                ORDER BY rank
                LIMIT 200
                """,
                parameters: [
                    .text(slug.description),
                    .queryFTS5(slug.description)
                ]
            )
            .compactMap({ row in
                if
                    let slugString: String = row.get(0),
                    let slug = Slug(slugString),
                    let content: String = row.get(1)
                {
                    let summary = Subtext(markup: content).summarize()
                    return EntryStub(
                        slug: slug,
                        title: summary.title ?? "",
                        excerpt: summary.excerpt ?? ""
                    )
                }
                return nil
            })

            // Create draft to use as fallback in event we don't find
            // a file with this slug.
            let draft = SaveEnvelope(
                state: .draft,
                value: SubtextFile(
                    slug: slug,
                    content: fallback
                )
            )

            // Retreive top entry from file system to ensure it is fresh.
            // If no file exists, then construct one using fallback content.
            // Wrap in SaveEnvelope envelope to indicate whether it
            // represents saved state on disk, or is a draft.
            let entry = readEntry(slug: slug).mapOr(
                { entry in SaveEnvelope(state: .saved, value: entry) },
                default: draft
            )

            return EntryDetail(
                slug: slug,
                entry: entry,
                backlinks: backlinks
            )
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Choose a random entry and read detailz
    func readRandomEntrySlug() -> AnyPublisher<Slug, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            try database.execute(
                sql: """
                SELECT slug
                FROM entry
                ORDER BY RANDOM()
                LIMIT 1
                """
            )
            .compactMap({ row in
                row.get(0).flatMap({ string in Slug(string) })
            })
            .first
            .unwrap(or: DatabaseServiceError.notFound)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
