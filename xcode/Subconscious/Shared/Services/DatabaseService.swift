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

struct DatabaseMigrationInfo: Hashable {
    var version: Int
    var didRebuild: Bool
}

struct DatabaseService {
    enum DatabaseServiceError: Error, LocalizedError {
        case pathNotInFilePath
        case randomEntryFailed
        case fileExists(Slug)

        var errorDescription: String? {
            switch self {
            case .pathNotInFilePath:
                return "DatabaseServiceError.pathNotInFilePath"
            case .randomEntryFailed:
                return "DatabaseServiceError.randomEntryFailed"
            case .fileExists(let slug):
                return "DatabaseServiceError.fileExists(\(slug))"
            }
        }
    }

    private var memos: MemoStore
    private var files: FileStore
    private var documentURL: URL
    private var databaseURL: URL
    private var database: SQLite3Database
    private var migrations: Migrations<AppMigrationEnvironment>

    init(
        documentURL: URL,
        databaseURL: URL,
        memos: MemoStore,
        files: FileStore,
        migrations: Migrations<AppMigrationEnvironment>
    ) {
        self.documentURL = documentURL
        self.databaseURL = databaseURL
        self.database = SQLite3Database(
            url: databaseURL,
            mode: .readwrite
        )
        self.migrations = migrations
        self.memos = memos
        self.files = files
    }

    /// Make sure database is up-to-date.
    /// Checks the user version, and if it is out of date, it deletes
    /// and recreates the database.
    ///
    /// Because we only use the database as a cache, we are able to rebuild
    /// it from scratch using the file system.
    ///
    /// - Returns the version of the database upon successful comple.
    private func migrate() throws -> Int {
        try self.migrations.migrate(
            database: self.database,
            environment: AppMigrationEnvironment(
                memos: memos,
                files: files
            )
        )
    }

    /// Migrate database off main thread, returning a publisher
    func migrateAsync() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            try migrate()
        }
    }

    /// Sync file system with database.
    /// Note file system is source-of-truth (leader).
    /// Syncing will never delete files on the file system.
    func syncDatabase() -> AnyPublisher<[FileFingerprintChange], Error> {
        CombineUtilities.async(qos: .utility) {
            // Left = Leader (files)
            let left: [FileFingerprint] = try memos.list()
                .compactMap({ slug in
                    guard let info = memos.info(slug) else {
                        return nil
                    }
                    return FileFingerprint(
                        slug: slug,
                        info: info
                    )
                })
            // Right = Follower (search index)
            let right: [FileFingerprint] = try database.execute(
                sql: "SELECT slug, modified, size FROM note"
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
            )
            .filter({ change in
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
                case .leftOnly(let left), .leftNewer(let left, _), .rightNewer(let left, _), .conflict(let left, _):
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
        entry: MemoEntry
    ) throws {
        try database.execute(
            sql: """
            INSERT INTO note (
                slug,
                headers,
                content_type,
                created,
                modified,
                title,
                body,
                excerpt,
                links,
                size
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(slug) DO UPDATE SET
                headers=excluded.headers,
                content_type=excluded.content_type,
                created=excluded.created,
                modified=excluded.modified,
                title=excluded.title,
                body=excluded.body,
                excerpt=excluded.excerpt,
                links=excluded.links,
                size=excluded.size
            """,
            parameters: [
                .text(String(describing: entry.slug)),
                .json(entry.contents.headers, or: "[]"),
                /// Use content type, or default to subtext
                .text(entry.contents.contentType),
                .date(entry.contents.created),
                .date(entry.contents.modified),
                .text(entry.contents.title),
                .text(entry.contents.body.description),
                .text(entry.contents.excerpt()),
                .json(entry.contents.slugs(), or: "[]"),
                .integer(
                    entry.contents.body.description
                        .lengthOfBytes(using: .utf8)
                )
            ]
        )
    }

    private func writeEntryToDatabase(slug: Slug) throws {
        var entry = try readEntry(slug: slug)
        /// Read created and modified times from file system
        let info = try memos.info(slug).unwrap()
        /// Set on headers
        entry.contents.created = info.created
        entry.contents.modified = info.modified
        try writeEntryToDatabase(entry: entry)
    }

    private func entryFileExists(_ slug: Slug) -> Bool {
        let url = slug.toURL(directory: documentURL, ext: "subtext")
        //  NOTE: It's important to use `.path` and not `.absolutePath`.
        //  For whatever reason, `.fileExists` will not find the file
        //  at its `.absolutePath`.
        //  2022-01-21 Gordon Brander
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Write entry to file system and database
    /// Also sets modified header to now.
    private func writeEntry(_ entry: MemoEntry) throws {
        var entry = entry
        entry.contents.modified = Date.now
        try memos.write(entry.slug, value: entry.contents)

        // Read modified date from file system directly after writing
        let info = try memos.info(entry.slug).unwrap()
        // Amend headers
        entry.contents.modified = info.modified
        try writeEntryToDatabase(entry: entry)
    }
    
    func writeEntryAsync(_ entry: MemoEntry) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
            try writeEntry(entry)
        }
    }
    
    /// Delete entry from database
    private func deleteEntryFromDatabase(slug: Slug) throws {
        try database.execute(
            sql: """
            DELETE FROM note WHERE slug = ?
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
    
    /// Move entry to a new location, updating file system and database.
    private func moveEntry(from: EntryLink, to: EntryLink) throws {
        guard from.slug != to.slug else {
            throw DatabaseServiceError.fileExists(to.slug)
        }
        // Make sure we're writing to an empty location
        guard !entryFileExists(to.slug) else {
            throw DatabaseServiceError.fileExists(to.slug)
        }
        let fromFile = try readEntry(slug: from.slug)
        // Make a copy representing new location and set new title and slug
        var toFile = fromFile
        toFile.setLink(to)
        // Write to new destination
        try writeEntry(toFile)
        // ...Then delete old entry
        try deleteEntry(slug: fromFile.slug)
    }
    
    /// Move entry to a new location, updating file system and database.
    /// - Returns a combine publisher
    func moveEntryAsync(
        from: EntryLink,
        to: EntryLink
    ) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try moveEntry(from: from, to: to)
        }
    }
    
    /// Merge child entry into parent entry.
    /// - Appends `child` to `parent`
    /// - Writes the combined content to `parent`
    /// - Deletes `child`
    private func mergeEntry(
        parent: Slug,
        child: Slug
    ) throws {
        let childEntry = try readEntry(slug: child)
        
        let parentEntry = try readEntry(slug: parent)
            .merge(childEntry)
        
        //  First write the merged file to "to" location
        try writeEntry(parentEntry)
        //  Then delete child entry *afterwards*.
        //  We do this last to avoid data loss in case of write errors.
        try deleteEntry(slug: childEntry.slug)
    }
    
    /// Merge child entry into parent entry.
    /// - Appends `child` to `parent`
    /// - Writes the combined content to `parent`
    /// - Deletes `child`
    /// - Returns combine publisher
    func mergeEntryAsync(
        parent: EntryLink,
        child: EntryLink
    ) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try mergeEntry(parent: parent.slug, child: child.slug)
        }
    }
    
    /// Update the title of an entry, without changing its slug
    private func retitleEntry(
        from: EntryLink,
        to: EntryLink
    ) throws {
        guard from.linkableTitle != to.linkableTitle else {
            return
        }
        var entry = try readEntry(slug: from.slug)
        entry.contents.title = to.linkableTitle
        try writeEntry(entry)
    }
    
    /// Change title header of entry, without moving it.
    /// - Returns combine publisher
    func retitleEntryAsync(
        from: EntryLink,
        to: EntryLink
    ) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try retitleEntry(from: from, to: to)
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
                FROM note
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
                SELECT slug, modified, title, excerpt
                FROM note
                ORDER BY modified DESC
                LIMIT 1000
                """
            )
            .compactMap({ row in
                guard
                    let slug: Slug = row.get(0).flatMap({ string in
                        Slug(formatting: string)
                    }),
                    let modified: Date = row.get(1),
                    let title: String = row.get(2),
                    let excerpt: String = row.get(3)
                else {
                    return nil
                }
                return EntryStub(
                    link: EntryLink(slug: slug, title: title),
                    excerpt: excerpt,
                    modified: modified
                )
            })
        }
    }
    
    private func searchSuggestionsForZeroQuery() throws -> [Suggestion] {
        let suggestions = try database.execute(
            sql: """
            SELECT slug, title
            FROM note
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
        
        var special: [Suggestion] = []
        
        // Insert scratch
        if Config.default.scratchSuggestionEnabled {
            let now = Date.now
            let formatter = DateFormatter.scratchDateFormatter()
            if let slug = Slug(
                formatting: "inbox/\(formatter.string(from: now))"
            ) {
                special.append(
                    .scratch(
                        EntryLink(
                            slug: slug,
                            title: Config.default.scratchDefaultTitle
                        )
                    )
                )
            }
        }
        
        if Config.default.randomSuggestionEnabled {
            // Insert an option to load a random note if there are any notes.
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
            FROM note_search
            WHERE note_search MATCH ?
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
    //  TODO: Replace flag arguments with direct references feature flags
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
    
    /// Given
    /// - An entry link representing the current link for the file
    /// - An entry link representing the search query
    /// - And some results for existing entries
    /// ...Return an array of unique RenameSuggestions,
    /// sorted for presentation.
    ///
    /// We factor out this collation code to make it easier to test.
    ///
    /// - Returns an array of RenameSuggestion
    static func collateRenameSuggestions(
        current: EntryLink,
        query: EntryLink,
        results: [EntryLink]
    ) -> [RenameSuggestion] {
        var suggestions: OrderedDictionary<Slug, RenameSuggestion> = [:]
        // First append result for literal query
        if query.slug != current.slug {
            suggestions.updateValue(
                .move(
                    from: current,
                    to: query
                ),
                forKey: query.slug
            )
        }
        // If slug is the same but title changed, this is a retitle
        else if query.linkableTitle != current.linkableTitle {
            suggestions.updateValue(
                .retitle(
                    from: current,
                    to: query
                ),
                forKey: current.slug
            )
        }
        // Then append results from existing entries, potentially overwriting
        // result for literal query if identical.
        for result in results {
            /// If slug changed, this is a move
            if result.slug != current.slug {
                suggestions.updateValue(
                    .merge(
                        parent: result,
                        child: current
                    ),
                    forKey: result.slug
                )
            }
        }
        return Array(suggestions.values)
    }
    
    /// Given a query and a `current` slug, produce an array of suggestions
    /// for renaming the note.
    func searchRenameSuggestions(
        query: String,
        current: EntryLink
    ) -> AnyPublisher<[RenameSuggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            guard let queryEntryLink = EntryLink(title: query) else {
                return []
            }
            
            let results: [EntryLink] = try database.execute(
                sql: """
                SELECT slug, title
                FROM note_search
                WHERE note_search MATCH ?
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
            
            return Self.collateRenameSuggestions(
                current: current,
                query: queryEntryLink,
                results: results
            )
        }
    }
    
    func readDefaultLinkSuggestions() -> [LinkSuggestion] {
        // If default link suggestsions are toggled off, return empty array.
        guard Config.default.linksEnabled else {
            return []
        }
        return Config.default.linksFallback
            .map({ slug in .entry(EntryLink(slug: slug)) })
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
                    FROM note_search
                    WHERE note_search MATCH ?
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
    func createSearchHistoryItem(query: String) -> AnyPublisher<String, Error> {
        CombineUtilities.async(qos: .utility) {
            guard !query.isWhitespace else {
                return query
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
            
            return query
        }
    }
    
    /// Read an entry from the file system.
    /// Private syncronous API to read a Subtext file via its Slug
    /// Used by public async APIs.
    /// - Returns a SubtextFile with mended headers.
    private func readEntry(slug: Slug) throws -> MemoEntry {
        let memo = try memos.read(slug)
        return MemoEntry(slug: slug, contents: memo)
    }
    
    /// Sync version of readEntryDetail
    /// Use `readEntryDetail` API to call this async.
    private func readEntryDetail(
        link: EntryLink,
        fallback: String
    ) throws -> EntryDetail {
        // Get backlinks.
        // Use content indexed in database, even though it might be stale.
        let backlinks: [EntryStub] = try database.execute(
            sql: """
            SELECT slug, modified, title, excerpt
            FROM note_search
            WHERE slug != ? AND note_search.body MATCH ?
            ORDER BY rank
            LIMIT 200
            """,
            parameters: [
                .text(link.slug.description),
                .queryFTS5(link.slug.description)
            ]
        )
        .compactMap({ row in
            guard
                let slug: Slug = row.get(0).flatMap({ string in
                    Slug(formatting: string)
                }),
                let modified: Date = row.get(1),
                let title: String = row.get(2),
                let excerpt: String = row.get(3)
            else {
                return nil
            }
            return EntryStub(
                link: EntryLink(slug: slug, title: title),
                excerpt: excerpt,
                modified: modified
            )
        })
        // Retreive top entry from file system to ensure it is fresh.
        // If no file exists, return a draft, using fallback for title.
        guard let entry = try? readEntry(slug: link.slug) else {
            return EntryDetail(
                saveState: .draft,
                entry: MemoEntry(
                    slug: link.slug,
                    contents: Memo(
                        contentType: ContentType.subtext.rawValue,
                        created: Date.now,
                        modified: Date.now,
                        title: link.title,
                        fileExtension: ContentType.subtext.fileExtension,
                        other: [],
                        body: fallback
                    )
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
        link: EntryLink,
        fallback: String
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .utility) {
            try readEntryDetail(link: link, fallback: fallback)
        }
    }
    
    /// Get entry and backlinks from slug, using template file as a fallback.
    func readEntryDetail(
        link: EntryLink,
        template: Slug
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .utility) {
            let entry = try? readEntry(slug: template)
            let fallback = entry.mapOr(
                { entry in
                    String(describing: entry.contents.body)
                },
                default: ""
            )
            return try readEntryDetail(
                link: link,
                fallback: fallback
            )
        }
    }
    
    /// Select a random entry
    func readRandomEntry() -> EntryStub? {
        try? database.execute(
            sql: """
            SELECT slug, title, body, modified
            FROM note
            ORDER BY RANDOM()
            LIMIT 1
            """
        )
        .compactMap({ row in
            guard
                let slug: Slug = row.get(0).flatMap({ string in
                    Slug(formatting: string)
                }),
                let title: String = row.get(1),
                let body: String = row.get(2),
                let modified: Date = row.get(3)
            else {
                return nil
            }
            return EntryStub(
                link: EntryLink(slug: slug, title: title),
                excerpt: Subtext(markup: body).excerpt(),
                modified: modified
            )
        })
        .first
    }
    
    /// Select a random entry who's body matches a query string
    func readRandomEntryMatching(
        query: String
    ) -> EntryStub? {
        try? database.execute(
            sql: """
            SELECT slug, modified, title, body
            FROM note_search
            WHERE note_search.body MATCH ?
            ORDER BY RANDOM()
            LIMIT 1
            """,
            parameters: [
                .queryFTS5(query)
            ]
        )
        .compactMap({ row in
            guard
                let slug: Slug = row.get(0).flatMap({ string in
                    Slug(formatting: string)
                }),
                let modified: Date = row.get(1),
                let title: String = row.get(2),
                let body: String = row.get(3)
            else {
                return nil
            }
            return EntryStub(
                link: EntryLink(slug: slug, title: title),
                excerpt: Subtext(markup: body).excerpt(),
                modified: modified
            )
        })
        .first
    }
    
    /// Choose a random entry and publish slug
    func readRandomEntryLink() -> AnyPublisher<EntryLink, Error> {
        CombineUtilities.async(qos: .default) {
            try database.execute(
                sql: """
                SELECT slug, title
                FROM note
                ORDER BY RANDOM()
                LIMIT 1
                """
            )
            .compactMap({ row in
                guard
                    let slugString: String = row.get(0),
                    let slug = Slug(slugString),
                    let title: String = row.get(1)
                else {
                    return nil
                }
                return EntryLink(
                    slug: slug,
                    title: title
                )
            })
            .first
            .unwrap(DatabaseServiceError.randomEntryFailed)
        }
    }
}
