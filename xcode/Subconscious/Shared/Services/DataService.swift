//
//  DataService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/22/23.
//

import Foundation
import Combine

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

    /// Sync local state to gateway
    func syncSphere() -> AnyPublisher<String, Error> {
        CombineUtilities.async(qos: .utility) {
            try noosphere.sphere().sync()
        }
    }

    /// Migrate database off main thread, returning a publisher
    func migrateAsync() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .utility) {
            try database.migrate()
        }
    }

    func rebuildAsync() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .utility) {
            try database.rebuild()
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

        guard !Config.default.noosphere.enabled else {
            let sphere = try noosphere.sphere()
            let body = try entry.contents.body.toData().unwrap()
            try sphere.write(
                slug: entry.slug.description,
                contentType: entry.contents.contentType,
                additionalHeaders: entry.contents.headers,
                body: body
            )
            _ = try sphere.save()
            let info = FileInfo(
                created: entry.contents.created,
                modified: entry.contents.modified,
                size: body.count
            )
            try database.writeEntry(entry: entry, info: info)
            return
        }

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
        guard !Config.default.noosphere.enabled else {
            let sphere = try noosphere.sphere()
            try sphere.remove(slug: slug.description)
            _ = try sphere.save()
            try database.removeEntry(slug: slug)
            return
        }
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
        guard memos.info(to.slug) == nil else {
            throw DatabaseServiceError.fileExists(to.slug)
        }
        let fromMemo = try memos.read(from.slug).unwrap()
        let fromFile = MemoEntry(slug: from.slug, contents: fromMemo)
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
        let childEntry = MemoEntry(
            slug: child,
            contents: try memos.read(child).unwrap()
        )
        
        let parentEntry = MemoEntry(
            slug: parent,
            contents: try memos.read(parent).unwrap()
        )
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
        var entry = MemoEntry(
            slug: from.slug,
            contents: try memos.read(from.slug).unwrap()
        )
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

    func countEntries() throws -> Int {
        guard !Config.default.noosphere.enabled else {
            return try noosphere
                .sphere()
                .list()
                .count
        }
        return try database.countEntries().unwrap()
    }

    /// Count all entries
    func countEntries() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .userInteractive) {
            try countEntries()
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
            return database.searchLinkSuggestions(
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
    
    /// Sync version of readEntryDetail
    /// Use `readEntryDetail` API to call this async.
    private func readEntryDetail(
        link: EntryLink,
        fallback: String
    ) throws -> EntryDetail {
        let backlinks = database.readEntryBacklinks(slug: link.slug)

        guard !Config.default.noosphere.enabled else {
            // Retreive top entry from file system to ensure it is fresh.
            // If no file exists, return a draft, using fallback for title.
            let sphere = try noosphere.sphere()
            let slashlink = link.slug.toSlashlink()
            guard let memo = sphere.read(slashlink: slashlink)?.toMemo() else {
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
                            additionalHeaders: [],
                            body: fallback
                        )
                    ),
                    backlinks: backlinks
                )
            }
            // Return entry
            return EntryDetail(
                saveState: .saved,
                entry: MemoEntry(slug: link.slug, contents: memo),
                backlinks: backlinks
            )
        }

        // Retreive top entry from file system to ensure it is fresh.
        // If no file exists, return a draft, using fallback for title.
        guard let memo = memos.read(link.slug) else {
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
                        additionalHeaders: [],
                        body: fallback
                    )
                ),
                backlinks: backlinks
            )
        }
        // Return entry
        return EntryDetail(
            saveState: .saved,
            entry: MemoEntry(slug: link.slug, contents: memo),
            backlinks: backlinks
        )
    }

    /// Get entry and backlinks from slug, using string as a fallback.
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a
    /// clean slug.
    func readEntryDetailAsync(
        link: EntryLink,
        fallback: String
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .utility) {
            try readEntryDetail(link: link, fallback: fallback)
        }
    }
    
    /// Choose a random entry and publish slug
    func readRandomEntryLink() throws -> EntryLink {
        guard !Config.default.noosphere.enabled else {
            let slugStrings = try noosphere.sphere().list()
            let slugString = try slugStrings.randomElement().unwrap()
            let slug = try Slug(slugString).unwrap()
            return EntryLink(slug: slug)
        }
        guard let link = database.readRandomEntryLink() else {
            throw DatabaseServiceError.randomEntryFailed
        }
        return link
    }

    /// Choose a random entry and publish slug
    func readRandomEntryLinkAsync() -> AnyPublisher<EntryLink, Error> {
        CombineUtilities.async(qos: .default) {
            try readRandomEntryLink()
        }
    }
}
