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
        case fileExists
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
        entry: SubtextFile,
        fingerprint: FileFingerprint.Attributes
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
                .text(entry.title()),
                .text(String(describing: entry)),
                .date(fingerprint.modifiedDate),
                .integer(fingerprint.size)
            ]
        )
    }

    private func entryFileExists(_ slug: Slug) -> Bool {
        let url = slug.toURL(directory: documentURL, ext: "subtext")
        //  NOTE: It's important to use `.path` and not `.absolutePath`.
        //  For whatever reason, `.fileExists` will not find the file
        //  at its `.absolutePath`.
        //  2022-01-21 Gordon Brander
        return FileManager.default.fileExists(atPath: url.path)
    }

    private func writeEntryToDatabase(slug: Slug) throws {
        let entry = try readEntry(slug: slug).unwrap()
        let fingerprint = try FileFingerprint
            .Attributes(url: entry.url(directory: documentURL))
            .unwrap()
        try writeEntryToDatabase(entry: entry, fingerprint: fingerprint)
    }

    private func writeEntry(_ entry: SubtextFile) throws {
        let modifiedEntry = entry.modified(Date.now)
        try modifiedEntry.write(directory: documentURL)
        // Read modified date from file system directly after writing
        let fingerprint = try FileFingerprint
            .Attributes(url: entry.url(directory: documentURL))
            .unwrap()
        try writeEntryToDatabase(
            entry: modifiedEntry,
            fingerprint: fingerprint
        )
    }

    func writeEntryAsync(_ entry: SubtextFile) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
            try writeEntry(entry)
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

    /// Delete entry from file system and database
    private func deleteEntry(slug: Slug) throws {
        let url = slug.toURL(directory: documentURL, ext: "subtext")
        try FileManager.default.removeItem(at: url)
        try deleteEntryFromDatabase(slug: slug)
    }

    /// Delete entry from file system and database
    func deleteEntryAsync(slug: Slug) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .background) {
            try deleteEntry(slug: slug)
        }
    }

    /// Rename file in file system and database
    private func moveEntry(from: Slug, to: EntryLink) throws {
        guard from != to.slug else {
            throw DatabaseServiceError.fileExists
        }
        let fromFile = try readEntry(slug: from).unwrap()
        // Set new title and slug
        let toFile = fromFile.slugAndTitle(to)
        // Make sure we're writing to an empty location
        guard !entryFileExists(to.slug) else {
            throw DatabaseServiceError.fileExists
        }
        // Write to new destination
        try writeEntry(toFile)
        // ...Then delete old entry
        try deleteEntry(slug: fromFile.slug)
    }

    /// Merge two files together
    /// - Appends `from` to `to`
    /// - Writes the combined content to `to`
    /// - Deletes `from`
    private func mergeEntryFile(
        parent: Slug,
        child: Slug
    ) throws {
        let childEntry = try readEntry(slug: child).unwrap()

        let parentEntry = try readEntry(slug: parent)
            .unwrap()
            .merge(childEntry)

        //  First write the merged file to "to" location
        try writeEntry(parentEntry)
        //  Then delete child entry *afterwards*.
        //  We do this last to avoid data loss in case of write errors.
        try deleteEntry(slug: childEntry.slug)
    }

    /// Rename or merge entry.
    /// Updates both database and file system.
    func renameOrMergeEntry(
        from: EntryLink,
        to: EntryLink
    ) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
            // If slug is the same, but titles have changed, change title
            if from.slug == to.slug && from.linkableTitle != to.linkableTitle {
                var entry = try readEntry(slug: to.slug)
                    .unwrap(DatabaseServiceError.notFound)
                entry.headers["Title"] = to.linkableTitle
                try writeEntry(entry)
                return
            }
            //  If file already exists, perform a merge.
            //  Otherwise, perform a rename.
            else if entryFileExists(to.slug) {
                try mergeEntryFile(
                    parent: to.slug,
                    child: from.slug
                )
                return
            } else {
                try moveEntry(from: from.slug, to: to)
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
                SELECT slug, body, modified
                FROM entry_search
                ORDER BY modified DESC
                LIMIT 1000
                """
            )
            .compactMap({ row in
                guard
                    let slugString: String = row.get(0),
                    let slug = Slug(slugString),
                    let body: String = row.get(1),
                    let modified: Date = row.get(2)
                else {
                    return nil
                }
                /// Read entry and mend headers using information
                /// from database.
                let entry = SubtextFile(slug: slug, content: body)
                    .mendingHeaders(modified: modified)
                return EntryStub(entry)
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

    /// Read an entry from the file system.
    /// Private syncronous API to read a Subtext file via its Slug
    /// Used by public async APIs.
    /// - Returns a SubtextFile with mended headers.
    private func readEntry(
        slug: Slug
    ) -> SubtextFile? {
        let url = slug.toURL(directory: documentURL, ext: "subtext")
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        guard
            let attributes = try? FileManager.default.attributesOfItem(
                atPath: url.absoluteString
            ),
            let modified = attributes[.modificationDate] as? Date,
            let created = attributes[.creationDate] as? Date
        else {
            return nil
        }

        return SubtextFile(slug: slug, content: content)
            .mendingHeaders(
                modified: modified,
                created: created
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
            guard
                let slugString: String = row.get(0),
                let slug = Slug(slugString),
                let body: String = row.get(1)
            else {
                return nil
            }
            let entry = SubtextFile(slug: slug, content: body)
            return EntryStub(entry)
        })
        // Retreive top entry from file system to ensure it is fresh.
        // If no file exists, return a draft, using fallback for title.
        guard let entry = readEntry(slug: slug) else {
            let now = Date.now
            return EntryDetail(
                saveState: .draft,
                entry: SubtextFile(
                    slug: slug,
                    title: fallback,
                    modified: now,
                    created: now,
                    body: ""
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
            let fallback = readEntry(slug: template)?.body ?? ""
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
