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

// MARK: SERVICE
/// Wraps both database and source-of-truth store, providing data
/// access methods for the app.
struct DataService {
    var documentURL: URL
    var databaseURL: URL
    var noosphere: NoosphereService
    var database: DatabaseService
    var memos: HeaderSubtextMemoStore

    init(
        documentURL: URL,
        databaseURL: URL,
        noosphere: NoosphereService,
        database: DatabaseService,
        memos: HeaderSubtextMemoStore
    ) {
        self.documentURL = documentURL
        self.databaseURL = databaseURL
        self.database = database
        self.noosphere = noosphere
        self.memos = memos
    }

    /// Migrate database off main thread, returning a publisher
    func migrateAsync() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .userInitiated) {
            try database.migrate()
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
            let right: [FileFingerprint] = try database.listFingerprints()
            
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
                    let memo = try memos.read(left.slug).unwrap()
                    let entry = MemoEntry(slug: left.slug, contents: memo)
                    let info = try memos.info(left.slug).unwrap()
                    try database.writeEntry(entry: entry, info: info)
                // .rightOnly = delete. Remove from search index
                case .rightOnly(let right):
                    try database.removeEntry(slug: right.slug)
                // .same = no change. Do nothing.
                case .same:
                    break
                }
            }
            return changes
        }
    }

    /// Write entry to file system and database
    /// Also sets modified header to now.
    func writeEntry(_ entry: MemoEntry) throws {
        var entry = entry
        entry.contents.modified = Date.now
        try memos.write(entry.slug, value: entry.contents)

        // Read modified/size from file system directly after writing.
        // Why: we use file system as source of truth and don't want any
        // discrepencies to sneak in (e.g. different time between write and
        // persistence on file system).
        let info = try memos.info(entry.slug).unwrap()
        try database.writeEntry(entry: entry, info: info)
    }
    
    func writeEntryAsync(_ entry: MemoEntry) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
            try writeEntry(entry)
        }
    }
    
    /// Delete entry from file system and database
    private func deleteEntry(slug: Slug) throws {
        try memos.remove(slug)
        try database.removeEntry(slug: slug)
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
        guard memos.info(to.slug) != nil else {
            throw DatabaseServiceError.fileExists(to.slug)
        }
        let fromFile = try readEntry(slug: from.slug).unwrap()
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
        var entry = try readEntry(slug: from.slug).unwrap()
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
    
    func listRecentEntries() -> AnyPublisher<[EntryStub], Error> {
        CombineUtilities.async(qos: .default) {
            database.listRecentEntries()
        }
    }

    /// Count all entries
    func countEntries() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .userInteractive) {
            try database.countEntries().unwrap()
        }
    }

    func searchSuggestions(
        query: String
    ) -> AnyPublisher<[Suggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            try database.searchSuggestions(query: query)
        }
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchLinkSuggestions(
        query: String,
        omitting invalidSuggestions: Set<Slug> = Set(),
        fallback: [LinkSuggestion] = []
    ) -> AnyPublisher<[LinkSuggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            database.searchLinkSuggestions(
                query: query,
                omitting: invalidSuggestions,
                fallback: fallback
            )
        }
    }
    
    func searchRenameSuggestions(
        query: String,
        current: EntryLink
    ) -> AnyPublisher<[RenameSuggestion], Error> {
        CombineUtilities.async(qos: .userInitiated) {
            database.searchRenameSuggestions(query: query, current: current)
        }
    }

    /// Log a search query in search history db
    func createSearchHistoryItem(query: String) -> AnyPublisher<String, Error> {
        CombineUtilities.async(qos: .utility) {
            database.createSearchHistoryItem(query: query)
        }
    }
    
    /// Read an entry from the file system.
    /// Private syncronous API to read a Subtext file via its Slug
    /// Used by public async APIs.
    /// - Returns a SubtextFile with mended headers.
    private func readEntry(slug: Slug) -> MemoEntry? {
        guard let memo = memos.read(slug) else {
            return nil
        }
        return MemoEntry(slug: slug, contents: memo)
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
            try database.readEntryDetail(link: link, fallback: fallback)
        }
    }
    
    /// Get entry and backlinks from slug, using template file as a fallback.
    func readEntryDetail(
        link: EntryLink,
        template: Slug
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .utility) {
            let entry = readEntry(slug: template)
            let fallback = entry.mapOr(
                { entry in
                    String(describing: entry.contents.body)
                },
                default: ""
            )
            return try database.readEntryDetail(link: link, fallback: fallback)
        }
    }
    
    /// Choose a random entry and publish slug
    func readRandomEntryLink() -> AnyPublisher<EntryLink, Error> {
        CombineUtilities.async(qos: .default) {
            guard let link = database.readRandomEntryLink() else {
                throw DatabaseServiceError.randomEntryFailed
            }
            return link
        }
    }
}

struct DatabaseService {
    let migrations: Migrations
    let database: SQLite3Database

    init(
        database: SQLite3Database,
        migrations: Migrations
    ) {
        self.migrations = migrations
        self.database = database
    }

    /// Make sure database is up-to-date.
    /// Checks the user version, and if it is out of date, it deletes
    /// and recreates the database.
    ///
    /// Because we only use the database as a cache, we are able to rebuild
    /// it from scratch using the file system.
    ///
    /// - Returns the version of the database upon successful comple.
    func migrate() throws -> Int {
        return try self.migrations.migrate(self.database)
    }

    /// Write entry syncronously
    func writeEntry(
        entry: MemoEntry,
        info: FileInfo
    ) throws {
        var entry = entry
        entry.contents.modified = info.modified
        entry.contents.created = info.created
        try database.execute(
            sql: """
            INSERT INTO memo (
                slug,
                content_type,
                created,
                modified,
                title,
                file_extension,
                headers,
                body,
                description,
                excerpt,
                links,
                size
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(slug) DO UPDATE SET
                content_type=excluded.content_type,
                created=excluded.created,
                modified=excluded.modified,
                title=excluded.title,
                file_extension=excluded.file_extension,
                headers=excluded.headers,
                body=excluded.body,
                description=excluded.description,
                excerpt=excluded.excerpt,
                links=excluded.links,
                size=excluded.size
            """,
            parameters: [
                .text(String(describing: entry.slug)),
                .text(entry.contents.contentType),
                .date(entry.contents.created),
                .date(entry.contents.modified),
                .text(entry.contents.title),
                .text(entry.contents.fileExtension),
                .json(entry.contents.headers, or: "[]"),
                .text(entry.contents.body),
                .text(entry.contents.plain()),
                .text(entry.contents.excerpt()),
                .json(entry.contents.slugs(), or: "[]"),
                .integer(info.size)
            ]
        )
    }
    
    /// Delete entry from database
    func removeEntry(slug: Slug) throws {
        try database.execute(
            sql: """
            DELETE FROM memo WHERE slug = ?
            """,
            parameters: [
                .text(slug.description)
            ]
        )
    }
    
    /// Count all entries
    func countEntries() -> Int? {
        // Use stale body content from db. It's faster, and these
        // are read-only teaser views.
        guard let results = try? database.execute(
            sql: """
            SELECT count(slug)
            FROM memo
            """
        ) else {
            return nil
        }
        return results.get(0)?.get(0)
    }
    
    /// List recent entries
    func listRecentEntries() -> [EntryStub] {
        guard let results = try? database.execute(
            sql: """
            SELECT slug, modified, title, excerpt
            FROM memo
            ORDER BY modified DESC
            LIMIT 1000
            """
        ) else {
            return []
        }
        return results.compactMap({ row in
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
    
    /// List file fingerprints for all memos.
    func listFingerprints() throws -> [FileFingerprint] {
        try database.execute(sql: "SELECT slug, modified, size FROM memo")
            .compactMap({ row in
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
    }

    private func searchSuggestionsForZeroQuery() throws -> [Suggestion] {
        let suggestions = try database.execute(
            sql: """
            SELECT slug, title
            FROM memo
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
            FROM memo_search
            WHERE memo_search MATCH ?
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
    ) throws -> [Suggestion] {
        if query.isWhitespace {
            return try searchSuggestionsForZeroQuery()
        } else {
            return try searchSuggestionsForQuery(query: query)
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
    ) -> [RenameSuggestion] {
        guard let queryEntryLink = EntryLink(title: query) else {
            return []
        }
        
        guard let results = try? database.execute(
            sql: """
            SELECT slug, title
            FROM memo_search
            WHERE memo_search MATCH ?
            ORDER BY rank
            LIMIT 25
            """,
            parameters: [
                .prefixQueryFTS5(query)
            ]
        ) else {
            return []
        }
        let entries = results.compactMap({ row in
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
            results: entries
        )
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchLinkSuggestions(
        query: String,
        omitting invalidSuggestions: Set<Slug> = Set(),
        fallback: [LinkSuggestion] = []
    ) -> [LinkSuggestion] {
        guard !query.isWhitespace else {
            return fallback
        }
        
        var suggestions: OrderedDictionary<Slug, LinkSuggestion> = [:]
        
        // Append literal
        if let literal = EntryLink(title: query) {
            suggestions[literal.slug] = .new(literal)
        }
        
        guard let results = try? database.execute(
            sql: """
            SELECT slug, title
            FROM memo_search
            WHERE memo_search MATCH ?
            ORDER BY rank
            LIMIT 25
            """,
            parameters: [
                .prefixQueryFTS5(query)
            ]
        ) else {
            return Array(suggestions.values)
        }
        let entries = results.compactMap({ row in
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
    
    /// Log a search query in search history db
    func createSearchHistoryItem(query: String) -> String {
        guard !query.isWhitespace else {
            return query
        }
        
        // Log search in database, along with number of hits
        do {
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
        } catch {}
        
        return query
    }
    
    /// Read an entry from the file system.
    /// Private syncronous API to read a Subtext file via its Slug
    /// Used by public async APIs.
    /// - Returns a SubtextFile with mended headers.
    func readEntry(slug: Slug) -> MemoEntry? {
        let results = try? database.execute(
            sql: """
            SELECT
                slug,
                content_type,
                created,
                modified,
                title,
                file_extension,
                body
            FROM memo
            LIMIT 1
            """
        )
        guard let first = results?.get(0) else {
            return nil
        }
        let contentType = ContentType.orFallback(
            string: first.get(1),
            fallback: .subtext
        )
        let created: Date = Date.from(first.get(2)) ?? Date.now
        let modified: Date = Date.from(first.get(3)) ?? Date.now
        let title = first.get(4) ?? ""
        guard let body: String = first.get(5) else {
            return nil
        }

        let memo = Memo(
            contentType: contentType.rawValue,
            created: created,
            modified: modified,
            title: title,
            fileExtension: contentType.fileExtension,
            other: [],
            body: body
        )

        return MemoEntry(
            slug: slug,
            contents: memo
        )
    }
    
    /// Sync version of readEntryDetail
    /// Use `readEntryDetail` API to call this async.
    func readEntryDetail(
        link: EntryLink,
        fallback: String
    ) throws -> EntryDetail {
        // Get backlinks.
        // Use content indexed in database, even though it might be stale.
        let backlinks: [EntryStub] = try database.execute(
            sql: """
            SELECT slug, modified, title, excerpt
            FROM memo_search
            WHERE slug != ? AND memo_search.description MATCH ?
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
        guard let entry = readEntry(slug: link.slug) else {
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
    
    func readRandomEntryInDateRange(startDate: Date, endDate: Date) -> EntryStub? {
        try? database.execute(
            sql: """
            SELECT slug, modified, title, excerpt
            FROM memo
            WHERE memo.modified BETWEEN ? AND ?
            ORDER BY RANDOM()
            LIMIT 1
            """,
            parameters: [
                .date(startDate),
                .date(endDate)
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
        .first
    }

    /// Select a random entry
    func readRandomEntry() -> EntryStub? {
        try? database.execute(
            sql: """
            SELECT slug, modified, title, excerpt
            FROM memo
            ORDER BY RANDOM()
            LIMIT 1
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
        .first
    }
    
    /// Select a random entry who's body matches a query string
    func readRandomEntryMatching(
        query: String
    ) -> EntryStub? {
        try? database.execute(
            sql: """
            SELECT slug, modified, title, body
            FROM memo_search
            WHERE memo_search MATCH ?
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
    func readRandomEntryLink() -> EntryLink? {
        try? database.execute(
            sql: """
            SELECT slug, title
            FROM memo
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
    }
}


// MARK: Migrations
extension Config {
    static let migrations = Migrations([
        SQLMigration(
            version: Int.from(iso8601String: "2021-11-04T12:00:00")!,
            sql: """
            CREATE TABLE search_history (
                id TEXT PRIMARY KEY,
                query TEXT NOT NULL,
                created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE entry (
              slug TEXT PRIMARY KEY,
              title TEXT NOT NULL DEFAULT '',
              body TEXT NOT NULL,
              modified TEXT NOT NULL,
              size INTEGER NOT NULL
            );
            CREATE VIRTUAL TABLE entry_search USING fts5(
              slug,
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
                  slug,
                  title,
                  body,
                  modified,
                  size
                )
              VALUES
                (
                  new.rowid,
                  new.slug,
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
                  slug,
                  title,
                  body,
                  modified,
                  size
                )
              VALUES
                (
                  new.rowid,
                  new.slug,
                  new.title,
                  new.body,
                  new.modified,
                  new.size
                );
            END;
            """
        ),
        SQLMigration(
            version: Int.from(iso8601String: "2022-11-04T15:38:00")!,
            sql: """
            /* Remove old tables */
            DROP TABLE IF EXISTS entry;
            DROP TABLE IF EXISTS entry_search;
            DROP TRIGGER IF EXISTS entry_search_before_update;
            DROP TRIGGER IF EXISTS entry_search_before_delete;
            DROP TRIGGER IF EXISTS entry_search_after_update;
            DROP TRIGGER IF EXISTS entry_search_after_insert;
            
            /* Create new memo table */
            CREATE TABLE memo (
                slug TEXT PRIMARY KEY,
                content_type TEXT NOT NULL,
                created TEXT NOT NULL,
                modified TEXT NOT NULL,
                title TEXT NOT NULL DEFAULT '',
                file_extension TEXT NOT NULL,
                /* Additional free-form headers */
                headers TEXT NOT NULL DEFAULT '[]',
                /* Actual source text */
                body TEXT NOT NULL,
                /* Subtext/plain text serialization of body for search purposes */
                description TEXT NOT NULL,
                /* Short description of body */
                excerpt TEXT NOT NULL DEFAULT '',
                /* List of all slugs in body */
                links TEXT NOT NULL DEFAULT '[]',
                /* Size of body (used in combination with modified for sync) */
                size INTEGER NOT NULL
            );
            
            CREATE VIRTUAL TABLE memo_search USING fts5(
                slug,
                content_type UNINDEXED,
                created UNINDEXED,
                modified UNINDEXED,
                title,
                file_extension UNINDEXED,
                headers UNINDEXED,
                body UNINDEXED,
                description,
                excerpt UNINDEXED,
                links UNINDEXED,
                size UNINDEXED,
                content="memo",
                tokenize="porter"
            );
            
            /*
            Create triggers to keep fts5 virtual table in sync with content table.

            Note: SQLite documentation notes that you want to modify the fts table *before*
            the external content table, hence the BEFORE commands.

            These triggers are adapted from examples in the docs:
            https://www.sqlite.org/fts3.html#_external_content_fts4_tables_
            */
            CREATE TRIGGER memo_search_before_update BEFORE UPDATE ON memo BEGIN
                DELETE FROM memo_search WHERE rowid=old.rowid;
            END;
            
            CREATE TRIGGER memo_search_before_delete BEFORE DELETE ON memo BEGIN
                DELETE FROM memo_search WHERE rowid=old.rowid;
            END;
            
            CREATE TRIGGER memo_search_after_update AFTER UPDATE ON memo BEGIN
                INSERT INTO memo_search (
                    rowid,
                    slug,
                    content_type,
                    created,
                    modified,
                    title,
                    file_extension,
                    headers,
                    body,
                    description,
                    excerpt,
                    links,
                    size
                )
                VALUES (
                    new.rowid,
                    new.slug,
                    new.content_type,
                    new.created,
                    new.modified,
                    new.title,
                    new.file_extension,
                    new.headers,
                    new.body,
                    new.description,
                    new.excerpt,
                    new.links,
                    new.size
                );
            END;

            CREATE TRIGGER memo_search_after_insert AFTER INSERT ON memo BEGIN
                INSERT INTO memo_search (
                    rowid,
                    slug,
                    content_type,
                    created,
                    modified,
                    title,
                    file_extension,
                    headers,
                    body,
                    description,
                    excerpt,
                    links,
                    size
                )
                VALUES (
                    new.rowid,
                    new.slug,
                    new.content_type,
                    new.created,
                    new.modified,
                    new.title,
                    new.file_extension,
                    new.headers,
                    new.body,
                    new.description,
                    new.excerpt,
                    new.links,
                    new.size
                );
            END;
            """
        )
    ])
}
