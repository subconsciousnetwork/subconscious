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
    case slashlinkMustBeAbsolute
    case pathNotInFilePath
    case randomEntryFailed
    case notFound(String)
    case sizeMissingForLocal

    var errorDescription: String? {
        switch self {
        case let .invalidStateTransition(from, to):
            return "Invalid state transition \(from) -> \(to)"
        case .notReady:
            return "Database not ready"
        case .slashlinkMustBeAbsolute:
            return "Slashlink must be absolute"
        case .pathNotInFilePath:
            return "Path not in file path"
        case .randomEntryFailed:
            return "Failed to get random entry"
        case .sizeMissingForLocal:
            return "Size missing for local memo. Size is required for local memos."
        case .notFound(let message):
            return "Not found: \(message)"
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

    func savepoint(_ savepoint: String) throws {
        try self.database.savepoint(savepoint)
    }

    func release(_ savepoint: String) throws {
        try self.database.release(savepoint)
    }

    func rollback(_ savepoint: String) throws {
        try self.database.rollback(savepoint)
    }

    /// Read sphere information for our sphere
    func readOurSphere() throws -> OurSphereRecord? {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        guard let row = try database.execute(
            sql: """
            SELECT did, since
            FROM our_sphere
            """
        ).first else {
            return nil
        }
        guard let identity = row.col(0)?.toString()?.toDid() else {
            throw CodingError.decodingError(
                message: "Failed to decode did from column: did"
            )
        }
        guard let since = row.col(1)?.toString() else {
            throw CodingError.decodingError(
                message: "Failed to decode cid from column: since"
            )
        }
        return OurSphereRecord(
            identity: identity,
            since: since
        )
    }

    /// Write sphere information for one of our spheres into the database
    func writeOurSphere(
        _ record: OurSphereRecord
    ) throws {
        try database.execute(
            sql: """
            INSERT OR REPLACE INTO our_sphere (
                did,
                since
            )
            VALUES (?, ?)
            """,
            parameters: [
                .text(record.identity.description),
                .text(record.since)
            ]
        )
    }
    
    /// Given a sphere did, read the sync info from the database (if any).
    func readPeer(identity: Did) throws -> PeerRecord? {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        let rows = try database.execute(
            sql: "SELECT petname, since FROM peer WHERE did = ?",
            parameters: [.text(identity.description)]
        )
        guard let row = rows.first else {
            return nil
        }
        guard let petname = row.col(0)?.toString()?.toPetname() else {
            throw CodingError.decodingError(
                message: "Could not decode petname"
            )
        }
        let since = row.col(1)?.toString()
        return PeerRecord(
            petname: petname,
            identity: identity,
            since: since
        )
    }
    
    /// Given a sphere petname, read the indexed info from the
    /// database (if any).
    func readPeer(petname: Petname) throws -> PeerRecord? {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        let rows = try database.execute(
            sql: """
            SELECT did, since
            FROM peer
            WHERE petname = ?
            """,
            parameters: [.text(petname.description)]
        )
        guard let row = rows.first else {
            return nil
        }
        guard let identity = row.col(0)?.toString()?.toDid() else {
            throw CodingError.decodingError(
                message: "Failed to decode did from column: did"
            )
        }
        let since = row.col(1)?.toString()
        return PeerRecord(
            petname: petname,
            identity: identity,
            since: since
        )
    }

    /// Write database metadata at string key
    func writePeer(
        _ record: PeerRecord
    ) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        try database.execute(
            sql: """
            INSERT OR REPLACE INTO peer (
                petname,
                did,
                since
            )
            VALUES (?, ?, ?)
            """,
            parameters: [
                .text(record.petname.description),
                .text(record.identity.description),
                .text(record.since)
            ]
        )
    }
    
    /// List all peers in database
    func listPeers() throws -> [PeerRecord] {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        return try database.execute(
            sql: """
            SELECT petname, did, since FROM peer;
            """
        ).map({ row in
            guard let petname = row.col(0)?.toString()?.toPetname() else {
                throw CodingError.decodingError(
                    message: "Failed to decode petname from row"
                )
            }
            guard let identity = row.col(1)?.toString()?.toDid() else {
                throw CodingError.decodingError(
                    message: "Failed to decode did from row"
                )
            }
            let since = row.col(2)?.toString()
            return PeerRecord(
                petname: petname,
                identity: identity,
                since: since
            )
        })
    }

    /// Purge all content of sphere with given DID from the database.
    ///
    /// This does not delete the content from file system or sphere,
    /// only removes knowledge of it from the database.
    func purgePeer(identity: Did) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        let savepoint = "purge"
        try database.savepoint(savepoint)
        do {
            try database.execute(
                sql: """
                DELETE FROM memo WHERE did = ?
                """,
                parameters: [.text(identity.description)]
            )
            // Remove sync info
            try database.execute(
                sql: """
                DELETE FROM peer WHERE did = ?
                """,
                parameters: [.text(identity.description)]
            )
            try database.release(savepoint)
        } catch {
            try database.rollback(savepoint)
            throw error
        }
    }

    /// Write entry syncronously
    func writeMemo(
        link: Link,
        memo: Memo,
        size: Int? = nil
    ) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        if link.isLocal && size == nil {
            throw DatabaseServiceError.sizeMissingForLocal
        }
        try database.execute(
            sql: """
            INSERT INTO memo (
                id,
                did,
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
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                did=excluded.did,
                slug=excluded.slug,
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
                .text(link.id),
                .text(link.did.description),
                .text(link.slug.description),
                .text(memo.contentType),
                .date(memo.created),
                .date(memo.modified),
                .text(memo.title()),
                .text(memo.fileExtension),
                .json(memo.headers, or: "[]"),
                .text(memo.body),
                .text(memo.plain()),
                .text(memo.excerpt()),
                .json(memo.slugs(), or: "[]"),
                .integer(size ?? 0)
            ]
        )
    }
    
    /// Delete entry from database
    func removeMemo(_ link: Link) throws {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        try database.execute(
            sql: """
            DELETE FROM memo WHERE id = ?
            """,
            parameters: [
                .text(link.id)
            ]
        )
    }
    
    /// Count all entries
    func countMemos() -> Int? {
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
    func listRecentMemos(owner: Did?) throws -> [EntryStub] {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady

        }
        
        var dids = [Did.local.description]
        if let owner = owner {
            dids.append(owner.description)
        }
        
        let results = try database.execute(
            sql: """
            SELECT id, modified, excerpt
            FROM memo WHERE did IN (SELECT value FROM json_each(?))
            ORDER BY modified DESC
            LIMIT 1000
            """,
            parameters: [
                .json(dids, or: "[]")
            ]
        )
        return results.compactMap({ row in
            guard
                let address = row.col(0)?
                    .toString()?
                    .toLink()?
                    .toSlashlink()?
                    .relativizeIfNeeded(did: owner),
                let modified = row.col(1)?.toDate(),
                let excerpt = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryStub(
                address: address,
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
            SELECT slug, modified, size
            FROM memo
            WHERE did = ?
            """,
            parameters: [
                .text(Did.local.description)
            ]
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

    private func searchSuggestionsForZeroQuery(
        owner: Did?
    ) throws -> [Suggestion] {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        let suggestions: [Suggestion] = try database.execute(
            sql: """
            SELECT id, title
            FROM memo
            ORDER BY modified DESC
            LIMIT 5
            """
        )
        .compactMap({ row in
            guard
                let address = row.col(0)?
                    .toString()?
                    .toLink()?
                    .toSlashlink()?
                    .relativizeIfNeeded(did: owner),
                let title = row.col(1)?.toString()
            else {
                return nil
            }
            return EntryLink(
                address: address,
                title: title
            )
        })
        .map({ (link: EntryLink) in
            Suggestion.memo(
                address: link.address,
                fallback: link.title
            )
        })
        
        var special: [Suggestion] = []
        
        // Insert quick-create suggestion
        if AppDefaults.standard.isNoosphereEnabled {
            special.append(.createPublicMemo(fallback: ""))
        }
        special.append(.createLocalMemo(fallback: ""))

        special.append(contentsOf: suggestions)

        if Config.default.randomSuggestionEnabled {
            // Insert an option to load a random note if there are any notes.
            if suggestions.count > 2 {
                special.append(.random)
            }
        }
        
        return special
    }
    
    private func searchSuggestionsForQuery(
        owner: Did?,
        query: String
    ) throws -> [Suggestion] {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        
        var suggestions: [Suggestion] = []
        
        // Create suggestions for the literal query
        if AppDefaults.standard.isNoosphereEnabled {
            suggestions.append(.createPublicMemo(fallback: query))
        }
        suggestions.append(.createLocalMemo(fallback: query))

        let memos: [Suggestion] = try database.execute(
            sql: """
            SELECT id, excerpt
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
            guard
                let address = row.col(0)?
                    .toString()?
                    .toLink()?
                    .toSlashlink()?
                    .relativizeIfNeeded(did: owner),
                let excerpt = row.col(1)?.toString()
            else {
                return  nil
            }
            return Suggestion.memo(address: address, fallback: excerpt)
        })
        suggestions.append(contentsOf: memos)
        return suggestions
    }
    
    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchSuggestions(
        owner: Did?,
        query: String
    ) throws -> [Suggestion] {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        if query.isWhitespace {
            return try searchSuggestionsForZeroQuery(
                owner: owner
            )
        } else {
            return try searchSuggestionsForQuery(
                owner: owner,
                query: query
            )
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
        current: Slashlink,
        query: Slashlink?,
        results: [Slashlink]
    ) -> [RenameSuggestion] {
        var suggestions: OrderedDictionary<Slug, RenameSuggestion> = [:]
        // First append result for literal query
        if let query = query {
            if query.slug != current.slug {
                suggestions.updateValue(
                    .move(
                        from: current,
                        to: query
                    ),
                    forKey: query.slug
                )
            }
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
        owner: Did?,
        query: String,
        current: Slashlink
    ) throws -> [RenameSuggestion] {
        guard self.state == .ready else {
            return []
        }
        
        // Create a suggestion for the literal query that has same
        // audience as current.
        let queryAddress = Func.run({
            let audience = current.toAudience()
            return Slug(formatting: query)?.toSlashlink(audience: audience)
        })
        
        var dids = [Did.local.description]
        if let owner = owner {
            dids.append(owner.description)
        }

        let results: [Slashlink] = try database
            .execute(
                sql: """
                SELECT id
                FROM memo_search
                WHERE memo_search MATCH ? AND did IN (SELECT value FROM json_each(?))
                ORDER BY rank
                LIMIT 25
                """,
                parameters: [
                    .prefixQueryFTS5(query),
                    .json(dids, or: "[]")
                ]
            )
            .compactMap({ row in
                row.col(0)?.toString()?.toSlashlink()
            })
        
        return Self.collateRenameSuggestions(
            current: current,
            query: queryAddress,
            results: results
        )
    }

    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    func searchLinkSuggestions(
        query: String,
        omitting invalidSuggestions: Set<Slashlink> = Set(),
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
        if
            let literal = query.toSlug()?
                .toLocalSlashlink()
                .toEntryLink(title: query)
        {
            suggestions[literal.address.slug] = .new(literal)
        }
        
        guard let results = try? database.execute(
            sql: """
            SELECT id, title
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
                let address = row.col(0)?.toString()?.toSlashlink(),
                let title = row.col(1)?.toString()
            else {
                return nil
            }
            return EntryLink(
                address: address,
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
    
    func readEntryBacklinks(
        owner: Did?,
        link: Link
    ) throws -> [EntryStub] {
        guard self.state == .ready else {
            throw DatabaseServiceError.notReady
        }
        // Get backlinks.
        // Use content indexed in database, even though it might be stale.
        guard let results = try? database.execute(
            sql: """
            SELECT id, modified, excerpt
            FROM memo_search
            WHERE id != ? AND memo_search.description MATCH ?
            ORDER BY rank
            LIMIT 200
            """,
            parameters: [
                .text(link.id),
                .queryFTS5(link.slug.description)
            ]
        ) else {
            return []
        }
        
        return results.compactMap({ row in
            guard
                let address = row.col(0)?
                    .toString()?
                    .toLink()?
                    .toSlashlink()?
                    .relativizeIfNeeded(did: owner),
                let modified = row.col(1)?.toDate(),
                let excerpt = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryStub(
                address: address.relativizeIfNeeded(did: owner),
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
            SELECT id, modified, excerpt
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
                let address = row.col(0)?.toString()?.toSlashlink(),
                let modified = row.col(1)?.toDate(),
                let excerpt = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryStub(
                address: address,
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
            SELECT id, modified, excerpt
            FROM memo
            ORDER BY RANDOM()
            LIMIT 1
            """
        )
        .compactMap({ row in
            guard
                let address = row.col(0)?.toString()?.toSlashlink(),
                let modified = row.col(1)?.toDate(),
                let excerpt = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryStub(
                address: address,
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
            SELECT id, modified, excerpt
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
                let address = row.col(0)?.toString()?.toSlashlink(),
                let modified = row.col(1)?.toDate(),
                let excerpt = row.col(2)?.toString()
            else {
                return nil
            }
            return EntryStub(
                address: address,
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
            SELECT id, title
            FROM memo
            ORDER BY RANDOM()
            LIMIT 1
            """
        )
        .compactMap({ row in
            guard
                let address = row.col(0)?.toString()?.toSlashlink(),
                let title = row.col(1)?.toString()
            else {
                return nil
            }
            return EntryLink(
                address: address,
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
            version: Int.from(iso8601String: "2023-05-18T16:39:00")!,
            sql: """
            /*
            A table that tracks sphere->database indexing info for our sphere.
            Currently there should be at most one row in this table.
            However, in future we may allow users to manage multiple spheres.
            
            Columns:
            - did: the identity of the peer sphere
            - since: the last indexed CID for our sphere
              (may be null if we have not yet indexed our sphere)
            */
            CREATE TABLE our_sphere (
                did TEXT PRIMARY KEY,
                since TEXT NOT NULL
            );
            
            /*
            A table that tracks sphere->database indexing info for peers.
            Columns:
            - petname: The petname for the peer sphere (primary key)
            - did: the identity of the peer sphere
            - since: the last indexed CID for the peer
              (may be null if we have not yet indexed the peer sphere)
            */
            CREATE TABLE peer (
                petname TEXT PRIMARY KEY,
                did TEXT NOT NULL,
                since TEXT
            );
            
            /* History of user search queries */
            CREATE TABLE search_history (
                id TEXT PRIMARY KEY,
                query TEXT NOT NULL,
                created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            
            /* Memo table contains the content of any plain-text memo */
            CREATE TABLE memo (
                id TEXT PRIMARY KEY,
                did TEXT NOT NULL,
                slug TEXT NOT NULL,
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
                id,
                did UNINDEXED,
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
                    id,
                    did,
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
                    new.id,
                    new.did,
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
                    id,
                    did,
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
                    new.id,
                    new.did,
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
