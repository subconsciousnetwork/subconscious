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

enum DatabaseMetaKeys: String {
    case sphereIdentity = "sphere_identity"
    case sphereVersion = "sphere_version"
    case ownerKeyName = "owner_key_name"
}

enum DatabaseServiceError: Error, LocalizedError {
    case invalidStateTransition(
        from: DatabaseServiceState,
        to: DatabaseServiceState
    )
    case notReady
    case pathNotInFilePath
    case randomEntryFailed
    case notFound(String)

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
        default:
            return String(describing: self)
        }
    }
}

final class DatabaseService {
    /// String used for identifying content with no sphere identity
    /// i.e. local content
    static let noSphereIdentityKey = "none"

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

    /// Read database metadata from string key
    func readMetadata(key: String) throws -> String {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        let rows = try database.execute(
            sql: "SELECT value FROM database_metadata WHERE key = ?",
            parameters: [.text(key)]
        )
        guard let version = rows.first?.col(0)?.toString() else {
            throw DatabaseServiceError.notFound(
                "No value found for key \(key)"
            )
        }
        return version
    }

    /// Read metadata from type-safe metadata key
    func readMetadata(key: DatabaseMetaKeys) throws -> String {
        try readMetadata(key: key.rawValue)
    }

    /// Write database metadata at string key
    func writeMetadatadata(key: String, value: String) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        try database.execute(
            sql: """
            INSERT OR REPLACE INTO database_metadata (
                key,
                value
            )
            VALUES (?, ?)
            """,
            parameters: [.text(key), .text(value)]
        )
    }

    /// Write database metadata at type-safe metadata key
    func writeMetadatadata(key: DatabaseMetaKeys, value: String) throws {
        try writeMetadatadata(key: key.rawValue, value: value)
    }

    /// Write entry syncronously
    func writeMemo(
        _ address: MemoAddress,
        memo: Memo
    ) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        guard let size = memo.size() else {
            throw CodingError.encodingError(
                message: "Faild to encode memo contents as UTF-8"
            )
        }
        try database.execute(
            sql: """
            INSERT OR REPLACE INTO memo (
                slug,
                audience,
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
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            parameters: [
                .text(address.slug.description),
                .text(address.audience.rawValue),
                .text(memo.contentType),
                .date(memo.created),
                .date(memo.modified),
                .text(memo.title),
                .text(memo.fileExtension),
                .json(memo.headers, or: "[]"),
                .text(memo.body),
                .text(memo.plain()),
                .text(memo.excerpt()),
                .json(memo.slugs(), or: "[]"),
                .integer(size)
            ]
        )
    }
    
    /// Delete entry from database
    func removeMemo(_ address: MemoAddress) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        try database.execute(
            sql: """
            DELETE FROM memo WHERE slug = ? AND audience = ?
            """,
            parameters: [
                .text(address.slug.description),
                .text(address.audience.rawValue)
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
            SELECT slug, audience, modified, title, excerpt
            FROM memo
            ORDER BY modified DESC
            LIMIT 1000
            """
        ) else {
            return []
        }
        return results.compactMap({ row in
            guard
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let modified = row.col(2)?.toDate(),
                let title = row.col(3)?.toString(),
                let excerpt = row.col(4)?.toString()
            else {
                return nil
            }
            let address = MemoAddress(slug: slug, audience: audience)
            return EntryStub(
                address: address,
                title: title,
                excerpt: excerpt,
                modified: modified
            )
        })
    }
    
    /// List file fingerprints for all memos.
    func listLocalMemoFingerprints() throws -> [FileFingerprint] {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        return try database.execute(
            sql: """
            SELECT slug, modified, size FROM memo WHERE audience = 'local'
            """
        )
        .compactMap({ row in
            if
                let slug = row.col(0)?.toString()?.toSlug(),
                let modified = row.col(1)?.toDate(),
                let size = row.col(2)?.toInt()
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
            SELECT slug, audience, title
            FROM memo
            ORDER BY modified DESC
            LIMIT 25
            """
        )
        .compactMap({ row in
            guard
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let title = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryLink(
                address: MemoAddress(slug: slug, audience: audience),
                title: title
            )
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
                            address: MemoAddress(slug: slug, audience: .local),
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
        guard let queryEntrySlug = Slug(formatting: query) else {
            return []
        }
        
        var suggestions: OrderedDictionary<Slug, Suggestion> = [:]
        
        // Create a suggestion for the literal query
        suggestions[queryEntrySlug] = .search(
            EntryLink(
                address: MemoAddress(slug: queryEntrySlug, audience: .local),
                title: query
            )
        )
        
        let entries: [EntryLink] = try database.execute(
            sql: """
            SELECT slug, audience, title
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
                    let slug = row.col(0)?.toString()?.toSlug(),
                    let audience = row.col(1)?.toString()?.toAudience(),
                    let title: String = row.get(2)
                {
                    return EntryLink(
                        address: MemoAddress(slug: slug, audience: audience),
                        title: title
                    )
                }
                return nil
            })
        
        // Insert entries into suggestions.
        // If literal query and an entry have the same slug,
        // entry will overwrite query.
        for entry in entries {
            suggestions.updateValue(.entry(entry), forKey: entry.address.slug)
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
        if query.address.slug != current.address.slug {
            suggestions.updateValue(
                .move(
                    from: current,
                    to: query
                ),
                forKey: query.address.slug
            )
        }
        // If slug is the same but title changed, this is a retitle
        else if query.linkableTitle != current.linkableTitle {
            suggestions.updateValue(
                .retitle(
                    from: current,
                    to: query
                ),
                forKey: current.address.slug
            )
        }
        // Then append results from existing entries, potentially overwriting
        // result for literal query if identical.
        for result in results {
            /// If slug changed, this is a move
            if result.address.slug != current.address.slug {
                suggestions.updateValue(
                    .merge(
                        parent: result,
                        child: current
                    ),
                    forKey: result.address.slug
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

        guard let queryEntryLink = EntryLink(
            title: query,
            audience: current.address.audience
        ) else {
            return []
        }
        
        guard let results = try? database.execute(
            sql: """
            SELECT slug, audience, title
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
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let title: String = row.get(2)
            {
                return EntryLink(
                    address: MemoAddress(slug: slug, audience: audience),
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
        omitting invalidSuggestions: Set<MemoAddress> = Set(),
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
        if let literal = EntryLink(title: query, audience: .local) {
            suggestions[literal.address.slug] = .new(literal)
        }
        
        guard let results = try? database.execute(
            sql: """
            SELECT slug, audience, title
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
        let entries: [EntryLink] = results.compactMap({ row in
            guard
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let title = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryLink(
                address: MemoAddress(slug: slug, audience: audience),
                title: title
            )
        })
        
        // Insert entries into suggestions.
        // If literal query and an entry have the same slug,
        // entry will overwrite query.
        for entry in entries {
            // Only insert suggestion if it is not in the set of
            // suggestions to omit.
            if !invalidSuggestions.contains(entry.address) {
                suggestions.updateValue(
                    .entry(entry),
                    forKey: entry.address.slug
                )
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
    
    func readEntryBacklinks(slug: Slug) -> [EntryStub] {
        guard self.state == .ready else {
            return []
        }

        // Get backlinks.
        // Use content indexed in database, even though it might be stale.
        guard let results = try? database.execute(
            sql: """
            SELECT slug, audience, modified, title, excerpt
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
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let modified = row.col(2)?.toDate(),
                let title = row.col(3)?.toString(),
                let excerpt = row.col(4)?.toString()
            else {
                return nil
            }
            let address = MemoAddress(slug: slug, audience: audience)
            return EntryStub(
                address: address,
                title: title,
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
            SELECT slug, audience, modified, title, excerpt
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
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let modified = row.col(2)?.toDate(),
                let title = row.col(3)?.toString(),
                let excerpt = row.col(4)?.toString()
            else {
                return nil
            }
            let address = MemoAddress(slug: slug, audience: audience)
            return EntryStub(
                address: address,
                title: title,
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
            SELECT slug, audience, modified, title, excerpt
            FROM memo
            ORDER BY RANDOM()
            LIMIT 1
            """
        )
        .compactMap({ row in
            guard
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let modified = row.col(2)?.toDate(),
                let title = row.col(3)?.toString(),
                let excerpt = row.col(4)?.toString()
            else {
                return nil
            }
            let address = MemoAddress(slug: slug, audience: audience)
            return EntryStub(
                address: address,
                title: title,
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
            SELECT slug, audience, modified, title, excerpt
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
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let modified = row.col(2)?.toDate(),
                let title = row.col(3)?.toString(),
                let excerpt = row.col(4)?.toString()
            else {
                return nil
            }
            let address = MemoAddress(slug: slug, audience: audience)
            return EntryStub(
                address: address,
                title: title,
                excerpt: excerpt,
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
            SELECT slug, audience, title
            FROM memo
            ORDER BY RANDOM()
            LIMIT 1
            """
        )
        .compactMap({ row in
            guard
                let slug = row.col(0)?.toString()?.toSlug(),
                let audience = row.col(1)?.toString()?.toAudience(),
                let title = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryLink(
                address: MemoAddress(slug: slug, audience: audience),
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
            version: Int.from(iso8601String: "2023-02-10T08:58:00")!,
            sql: """
            /*
            Key-value metadata related to the database.
            Note that database is not source of truth, and may be deleted
            and rebuilt. Metadata stored in this table should be about the
            database and expected to exist only for the lifetime of the
            database. Anything that needs to be persisted more permanently
            should be persisted via other mechanisms.
            */
            CREATE TABLE database_metadata (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            /* History of user search queries */
            CREATE TABLE search_history (
                id TEXT PRIMARY KEY,
                query TEXT NOT NULL,
                created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            /* Memo table contains the content of any plain-text memo */
            CREATE TABLE memo (
                slug TEXT NOT NULL,
                audience TEXT NOT NULL,
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
                size INTEGER NOT NULL,
                PRIMARY KEY (slug, audience)
            );

            CREATE VIRTUAL TABLE memo_search USING fts5(
                slug,
                audience UNINDEXED,
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
                    audience,
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
                    new.audience,
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
                    audience,
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
                    new.audience,
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
