//
//  DatabaseService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//
//  Handles reading from, writing to, and migrating database.

import Foundation
import OrderedCollections
import Combine

/// Enum representing the current readiness state of the database service
enum DatabaseServiceState: String {
    case initial = "initial"
    case broken = "broken"
    case ready = "ready"
}

struct DatabaseMigrationInfo: Hashable {
    var version: Int
    var didRebuild: Bool
}

enum DatabaseServiceError: Error, LocalizedError {
    case invalidStateTransition(
        from: DatabaseServiceState,
        to: DatabaseServiceState
    )
    case notReady
    case pathNotInFilePath
    case randomEntryFailed
    case fileExists(Slug)

    var errorDescription: String? {
        switch self {
        case let .invalidStateTransition(from, to):
            return "DatabaseServiceError.invalidStateTransition(\(from), \(to))"
        case .notReady:
            return "DatabaseServiceError.notReady"
        case .pathNotInFilePath:
            return "DatabaseServiceError.pathNotInFilePath"
        case .randomEntryFailed:
            return "DatabaseServiceError.randomEntryFailed"
        case .fileExists(let slug):
            return "DatabaseServiceError.fileExists(\(slug))"
        }
    }
}

final class DatabaseService {
    /// Publishes the current state of the database.
    /// Subscribe to be notified when database changes state.
    @Published private(set) var state: DatabaseServiceState
    let migrations: Migrations
    let database: SQLite3Database

    init(
        database: SQLite3Database,
        migrations: Migrations
    ) {
        self.migrations = migrations
        self.database = database
        self.state = .initial
    }

    /// Make sure database is up-to-date.
    /// - Returns the version of the database upon successful comple.
    func migrate() throws -> Int {
        guard state == .initial else {
            throw DatabaseServiceError.invalidStateTransition(
                from: state,
                to: .ready
            )
        }
        do {
            let version = try self.migrations.migrate(self.database)
            // If migration succeeded, mark state ready
            self.state = .ready
            return version
        } catch {
            // Mark state broken by default
            self.state = .broken
            throw error
        }
    }

    /// Deletes and rebuilds the database by applying migrations to a new
    /// database.
    func rebuild() throws -> Int {
        try self.database.delete()
        self.state = .initial
        do {
            let version = try self.migrations.migrate(self.database)
            // If migration succeeded, mark state ready
            self.state = .ready
            return version
        } catch {
            // Mark state broken by default
            self.state = .broken
            throw error
        }
    }

    func readSphereVersion(identity: String) throws -> String {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        let rows = try database.execute(
            sql: "SELECT version FROM sphere WHERE identity = ?",
            parameters: [.text(identity)]
        )
        let version = rows.first?.col(0)?.toString()
        return try version.unwrap()
    }

    /// Write sphere to database.
    /// In the case where a sphere with this identity exists already, the
    /// old record will be overwritten with the new data.
    func writeSphere(
        identity: String,
        version: String,
        ownerKeyName: String
    ) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        try database.execute(
            sql: """
            INSERT INTO sphere (
                identity,
                version,
                owner_key_name
            )
            VALUES (?, ?, ?)
            ON CONFLICT(slug) DO UPDATE SET
                version=version,
                owner_key_name=excluded.owner_key_name
            """,
            parameters: [
                .text(identity),
                .text(version),
                .text(ownerKeyName)
            ]
        )
    }

    func writeSphereVersion(
        identity: String,
        version: String
    ) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        try database.execute(
            sql: """
            UPDATE sphere
            SET version = ?
            WHERE identity = ?
            """,
            parameters: [
                .text(version),
                .text(identity)
            ]
        )
    }

    /// Write entry syncronously
    func writeEntry(
        entry: MemoEntry,
        info: FileInfo
    ) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
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
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
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
        guard self.state == .ready else {
            return nil
        }
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
        return results.first?.col(0)?.toInt()
    }
    
    /// List recent entries
    func listRecentEntries() -> [EntryStub] {
        guard self.state == .ready else {
            return []
        }
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
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        return try database.execute(
            sql: "SELECT slug, modified, size FROM memo"
        )
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
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
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
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
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
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
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
        guard self.state == .ready else {
            return []
        }

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
        guard self.state == .ready else {
            return fallback
        }

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
        guard self.state == .ready else {
            return query
        }

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
        guard self.state == .ready else {
            return nil
        }

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
        guard let first = results?.first else {
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
            additionalHeaders: [],
            body: body
        )

        return MemoEntry(
            slug: slug,
            contents: memo
        )
    }
    
    func readEntryBacklinks(slug: Slug) -> [EntryStub] {
        guard self.state == .ready else {
            return []
        }

        // Get backlinks.
        // Use content indexed in database, even though it might be stale.
        guard let results = try? database.execute(
            sql: """
            SELECT slug, modified, title, excerpt
            FROM memo_search
            WHERE slug != ? AND memo_search.description MATCH ?
            ORDER BY rank
            LIMIT 200
            """,
            parameters: [
                .text(slug.description),
                .queryFTS5(slug.description)
            ]
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
    
    func readRandomEntryInDateRange(
        startDate: Date,
        endDate: Date
    ) -> EntryStub? {
        guard self.state == .ready else {
            return nil
        }
        
        return try? database.execute(
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
        guard self.state == .ready else {
            return nil
        }

        return try? database.execute(
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
        guard self.state == .ready else {
            return nil
        }
        
        return try? database.execute(
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
        guard self.state == .ready else {
            return nil
        }

        return try? database.execute(
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
            version: Int.from(iso8601String: "2023-01-03T11:47:00")!,
            sql: """
            /* History of user search queries */
            CREATE TABLE search_history (
                id TEXT PRIMARY KEY,
                query TEXT NOT NULL,
                created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            /* Sphere table keeps information on the spheres we're syncing with */
            CREATE TABLE sphere (
                identity TEXT PRIMARY KEY,
                version TEXT NOT NULL,
                owner_key_name TEXT NOT NULL
            );

            /* Memo table contains the content of any plain-text memo */
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
