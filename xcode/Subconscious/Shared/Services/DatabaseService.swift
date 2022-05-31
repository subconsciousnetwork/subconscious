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

    /// Close database connection and delete database file
    func delete() -> AnyPublisher<Void, Error> {
        CombineUtilities.async(
            qos: .background,
            execute: {
                database.close()
                try FileManager.default.removeItem(at: databaseURL)
            }
        )
    }

    func migrate() -> AnyPublisher<SQLite3Migrations.MigrationSuccess, Error> {
        CombineUtilities.async(
            qos: .userInitiated,
            execute: {
                try migrations.migrate(database: database)
            }
        )
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
    }

    /// Write entry syncronously
    private func writeEntryToDatabase(
        entry: SubtextFile
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
                .text(String(describing: entry.slug)),
                .text(entry.title),
                .text(String(describing: entry)),
                .date(entry.modified),
                .integer(entry.size)
            ]
        )
    }

    private func writeEntryToDatabase(slug: Slug) throws {
        var entry = try SubtextFile(slug: slug, directory: documentURL)
            .unwrap()
        let fingerprint = try FileFingerprint
            .Attributes(url: entry.url(directory: documentURL))
            .unwrap()
        entry.modified = fingerprint.modifiedDate
        return try writeEntryToDatabase(entry: entry)
    }

    func writeEntry(entry: SubtextFile) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
            var entry = entry
            // Write contents to file
            try entry.write(directory: documentURL)
            // Read modified date from file system directly after writing
            let fingerprint = try FileFingerprint
                .Attributes(url: entry.url(directory: documentURL))
                .unwrap()
            // Set modified date on entry
            entry.modified = fingerprint.modifiedDate
            return try writeEntryToDatabase(entry: entry)
        }
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
    }

    /// Rename file in file system
    private func moveEntryFile(from: Slug, to: Slug) throws {
        let fromFile = try SubtextFile(slug: from, directory: documentURL)
            .unwrap()
        let toFile = SubtextFile(slug: to, content: fromFile.content)
        try toFile.write(directory: documentURL)
        try FileManager.default.removeItem(
            at: fromFile.url(directory: documentURL)
        )
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
        .appending(fromFile)

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
        CombineUtilities.async(qos: .utility) {
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
    }

    /// Count all entries
    func countEntries() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .userInteractive) {
            // Use stale body content from db. It's faster, and these
            // are read-only teaser views.
            try database.execute(
                sql: """
                SELECT count(slug)
                FROM entry
                """
            )
            .compactMap({ row in
                row.get(0)
            })
            .first
            .unwrap(or: 0)
        }
    }

    /// List recent entries
    func listRecentEntries() -> AnyPublisher<[EntryStub], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            // Use stale body content from db. It's faster, and these
            // are read-only teaser views.
            try database.execute(
                sql: """
                SELECT slug, body, title, modified
                FROM entry_search
                ORDER BY modified DESC
                LIMIT 1000
                """
            )
            .compactMap({ row in
                if
                    let slugString: String = row.get(0),
                    let slug = Slug(slugString),
                    let body: String = row.get(1),
                    let title: String = row.get(2),
                    let modified: Date = row.get(3)
                {
                    var entry = SubtextFile(slug: slug, content: body)
                    entry.modified = modified
                    entry.title = title
                    return EntryStub(entry)
                }
                return nil
            })
        }
    }

    private func searchSuggestionsForZeroQuery(
        isJournalSuggestionEnabled: Bool,
        isScratchSuggestionEnabled: Bool,
        isRandomSuggestionEnabled: Bool
    ) throws -> [Suggestion] {
        let suggestions = try database.execute(
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

        let now = Date.now
        let dateTimeFormatter = ISO8601DateFormatter.internet()
        let dateTime = dateTimeFormatter.string(from: now)
        let dateFormatter = DateFormatter.yyyymmdd()
        let date = dateFormatter.string(from: now)

        var special: [Suggestion] = []

        // Insert scratch
        if isScratchSuggestionEnabled {
            if let slug = Slug(formatting: "inbox/\(dateTime)") {
                special.append(
                    .scratch(
                        EntryLink(
                            slug: slug,
                            title: date
                        )
                    )
                )
            }
        }

        // Insert journal
        if isJournalSuggestionEnabled {
            if let slug = Slug(formatting: "journal/\(date)") {
                special.append(
                    .journal(
                        EntryLink(
                            slug: slug,
                            title: date
                        )
                    )
                )
            }
        }

        if isRandomSuggestionEnabled {
            // Insert an option to load a random idea if there are any ideas.
            if suggestions.count > 2 {
                special.append(.random)
            }
        }

        special.append(contentsOf: suggestions)

        return special
    }

    private func searchSuggestionsForQuery(
        query: String
    ) throws -> [Suggestion] {
        // If slug is invalid, return empty suggestions
        guard let queryEntryLink = EntryLink(title: query) else {
            return []
        }

        var suggestions: OrderedDictionary<Slug, Suggestion> = [:]

        // Create a suggestion for the literal query
        suggestions[queryEntryLink.slug] = .search(queryEntryLink)

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
        query: String,
        isJournalSuggestionEnabled: Bool,
        isScratchSuggestionEnabled: Bool,
        isRandomSuggestionEnabled: Bool
    ) -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            if query.isWhitespace {
                return try searchSuggestionsForZeroQuery(
                    isJournalSuggestionEnabled: isJournalSuggestionEnabled,
                    isScratchSuggestionEnabled: isScratchSuggestionEnabled,
                    isRandomSuggestionEnabled: isRandomSuggestionEnabled
                )
            } else {
                return try searchSuggestionsForQuery(query: query)
            }
        }
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
    }

    func readDefaultLinkSuggestions(config: Config) -> [LinkSuggestion] {
        // If default link suggestsions are toggled off, return empty array.
        guard config.linksEnabled else {
            return []
        }
        guard let linksEntry = readEntry(slug: config.linksTemplate) else {
            return config.linksFallback.map({ slug in
                .entry(
                    EntryLink(slug: slug)
                )
            })
        }
        return linksEntry.dom.entryLinks.map(LinkSuggestion.entry)
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchLinkSuggestions(
        query: String,
        omitting invalidSuggestions: Set<Slug> = Set(),
        fallback: [LinkSuggestion] = []
    ) -> AnyPublisher<[LinkSuggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            guard !query.isWhitespace else {
                return fallback
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
                        .prefixQueryFTS5(query)
                    ]
                )
                .compactMap({ row in
                    if
                        let slugString: String = row.get(0),
                        let titleString: String = row.get(1),
                        let slug = Slug(slugString)
                    {
                        return EntryLink(
                            slug: slug,
                            title: titleString
                        )
                    }
                    return nil
                })

            // Insert entries into suggestions.
            // If literal query and an entry have the same slug,
            // entry will overwrite query.
            for entry in entries {
                // Only insert suggestion if it is not in the set of
                // suggestions to omit.
                if !invalidSuggestions.contains(entry.slug) {
                    suggestions.updateValue(.entry(entry), forKey: entry.slug)
                }
            }

            return Array(suggestions.values)
        }
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
    }

    /// Private syncronous API to read a Subtext file via its Slug
    /// Used by public async APIs.
    private func readEntry(
        slug: Slug
    ) -> SubtextFile? {
        SubtextFile(
            slug: slug,
            directory: documentURL
        )
    }

    /// Sync version of readEntryDetail
    /// Use `readEntryDetail` API to call this async.
    private func readEntryDetail(
        slug: Slug,
        fallback: String
    ) throws -> EntryDetail {
        // Get backlinks.
        // Use content indexed in database, even though it might be stale.
        let backlinks: [EntryStub] = try database.execute(
            sql: """
            SELECT slug, body, modified
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
                let body: String = row.get(1),
                let modified: Date = row.get(2)
            {
                let summary = Subtext.parse(markup: body).summarize()
                return EntryStub(
                    slug: slug,
                    title: summary.title ?? "",
                    excerpt: summary.excerpt ?? "",
                    modified: modified
                )
            }
            return nil
        })
        // Retreive top entry from file system to ensure it is fresh.
        // If no file exists, return a draft with fallback content.
        guard let entry = readEntry(slug: slug) else {
            return EntryDetail(
                saveState: .draft,
                entry: SubtextFile(
                    slug: slug,
                    content: fallback
                ),
                backlinks: backlinks
            )
        }
        // Return entry
        return EntryDetail(
            saveState: .saved,
            entry: entry,
            backlinks: backlinks
        )
    }

    /// Get entry and backlinks from slug, using string as a fallback.
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a
    /// clean slug.
    func readEntryDetail(
        slug: Slug,
        fallback: String
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .utility) {
            try readEntryDetail(slug: slug, fallback: fallback)
        }
    }

    /// Get entry and backlinks from slug, using template file as a fallback.
    func readEntryDetail(
        slug: Slug,
        template: Slug
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .utility) {
            let fallback = readEntry(slug: template)?.content ?? ""
            return try readEntryDetail(
                slug: slug,
                fallback: fallback
            )
        }
    }

    /// Choose a random entry and read detailz
    func readRandomEntrySlug() -> AnyPublisher<Slug, Error> {
        CombineUtilities.async(qos: .userInteractive) {
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
            .unwrap(DatabaseServiceError.notFound)
        }
    }
}
