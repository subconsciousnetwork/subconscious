//
//  DataService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/22/23.
//
import Foundation
import Combine

enum DataServiceError: Error {
    case fileExists(String)
    case memoNotFound(String)
    case defaultSphereNotFound
    case sphereExists
    case noosphereNotEnabled(String)
}

// MARK: SERVICE
/// Wraps both database and source-of-truth store, providing data
/// access methods for the app.
struct DataService {
    var documentURL: URL
    var databaseURL: URL
    var noosphere: NoosphereService
    var database: DatabaseService
    var local: HeaderSubtextMemoStore

    init(
        documentURL: URL,
        databaseURL: URL,
        noosphere: NoosphereService,
        database: DatabaseService,
        local: HeaderSubtextMemoStore
    ) {
        self.documentURL = documentURL
        self.databaseURL = databaseURL
        self.database = database
        self.noosphere = noosphere
        self.local = local
    }

    /// Determine if first run should show
    func shouldShowFirstRun() -> Bool {
        // Do not show first run if Noosphere is disabled
        guard Config.default.noosphere.enabled else {
            return false
        }
        let isComplete = AppDefaults.standard.firstRunComplete
        return !isComplete
    }

    /// Create a default sphere for user and persist sphere details
    /// - Returns: SphereReceipt
    /// Will not create sphere if a sphereIdentity already appears in
    /// the user defaults.
    func createSphere(ownerKeyName: String) throws -> SphereReceipt {
        guard AppDefaults.standard.sphereIdentity == nil else {
            throw DataServiceError.sphereExists
        }
        let sphereReceipt = try noosphere.createSphere(
            ownerKeyName: ownerKeyName
        )
        // Persist sphere identity to user defaults.
        // NOTE: we do not persist the mnemonic, since it would be insecure.
        // Instead, we return the receipt so that mnemonic can be displayed
        // and discarded.
        AppDefaults.standard.sphereIdentity = sphereReceipt.identity
        AppDefaults.standard.ownerKeyName = ownerKeyName
        return sphereReceipt
    }

    /// Sync local state to gateway
    func syncSphereWithGateway() -> AnyPublisher<String, Error> {
        CombineUtilities.async(qos: .utility) {
            try noosphere.sync()
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

    func syncSphereWithDatabase() throws -> String {
        let identity = try noosphere.identity()
        let version = try noosphere.version()
        let since = try? database.readMetadata(key: .sphereVersion)
        let changes = try noosphere.changes(since)
        for change in changes {
            guard let address = MemoAddress(
                formatting: change,
                audience: .public
            ) else {
                continue
            }
            let slashlink = address.slug.toSlashlink()
            // If memo does exist, write it to database
            // Sphere content is always public right now
            if let memo = noosphere.read(slashlink: slashlink)?.toMemo() {
                try database.writeMemo(
                    address,
                    memo: memo
                )
            }
            // If memo does not exist, that means change was a remove
            else {
                try database.removeMemo(address)
            }
        }
        try database.writeMetadatadata(key: .sphereIdentity, value: identity)
        try database.writeMetadatadata(key: .sphereVersion, value: version)
        return version
    }

    func syncSphereWithDatabaseAsync() -> AnyPublisher<String, Error> {
        CombineUtilities.async(qos: .utility) {
            try syncSphereWithDatabase()
        }
    }

    /// Sync file system with database.
    /// Note file system is source-of-truth (leader).
    /// Syncing will never delete files on the file system.
    func syncLocalWithDatabase() -> AnyPublisher<[FileFingerprintChange], Error> {
        CombineUtilities.async(qos: .utility) {
            // Left = Leader (files)
            let left: [FileFingerprint] = try local.list()
                .compactMap({ slug in
                    guard let info = local.info(slug) else {
                        return nil
                    }
                    return FileFingerprint(
                        slug: slug,
                        info: info
                    )
                })
            // Right = Follower (search index)
            let right = try database.listLocalMemoFingerprints()
            
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
                    var memo = try local.read(left.slug).unwrap()
                    // Read info from file system and set modified time
                    let info = try local.info(left.slug).unwrap()
                    memo.modified = info.modified
                    try database.writeMemo(
                        MemoAddress(slug: left.slug, audience: .local),
                        memo: memo
                    )
                // .rightOnly = delete. Remove from search index
                case .rightOnly(let right):
                    try database.removeMemo(
                        MemoAddress(slug: right.slug, audience: .local)
                    )
                // .same = no change. Do nothing.
                case .same:
                    break
                }
            }
            return changes
        }
    }

    /// Read memo from sphere or local
    private func readMemo(
        address: MemoAddress
    ) -> Memo? {
        switch address.audience {
        case .public:
            return noosphere
                .read(slashlink: address.slug.toSlashlink())?
                .toMemo()
        case .local:
            return local.read(address.slug)
        }
    }

    /// Write entry to file system and database
    /// Also sets modified header to now.
    private func writeMemo(
        address: MemoAddress,
        memo: Memo
    ) throws {
        var memo = memo
        memo.modified = Date.now

        switch address.audience {
        case .public:
            let body = try memo.body.toData().unwrap()
            try noosphere.write(
                slug: address.slug.description,
                contentType: memo.contentType,
                additionalHeaders: memo.headers,
                body: body
            )
            try noosphere.save()
            // Write to database
            try database.writeMemo(
                address,
                memo: memo
            )
            return
        case .local:
            try local.write(address.slug, value: memo)
            // Read modified/size from file system directly after writing.
            // Why: we use file system as source of truth and don't want any
            // discrepencies to sneak in (e.g. different time between write and
            // persistence on file system).
            let info = try local.info(address.slug).unwrap()
            memo.modified = info.modified
            try database.writeMemo(
                address,
                memo: memo
            )
            return
        }
    }

    private func writeEntry(_ entry: MemoEntry) throws {
        try writeMemo(address: entry.address, memo: entry.contents)
    }

    func writeEntryAsync(_ entry: MemoEntry) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
            try writeEntry(entry)
        }
    }
    
    /// Delete entry from file system and database
    private func deleteMemo(_ address: MemoAddress) throws {
        switch address.audience {
        case .local:
            try local.remove(address.slug)
            try database.removeMemo(address)
            return
        case .public:
            try noosphere.remove(slug: address.slug.description)
            try noosphere.save()
            try database.removeMemo(address)
            return
        }
    }
    
    /// Delete entry from file system and database
    func deleteMemoAsync(_ address: MemoAddress) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .background) {
            try deleteMemo(address)
        }
    }
    
    /// Update audience for memo.
    /// This moves memo from sphere to local or vise versa.
    private func updateAudience(
        address: MemoAddress,
        audience: Audience
    ) throws -> MemoAddress {
        // Exit early if no change is needed
        guard address.audience != audience else {
            return address
        }
        guard let memo = readMemo(address: address) else {
            throw DataServiceError.memoNotFound(
                "No memo found for address: \(address)"
            )
        }
        let newAddress = address.withAudience(audience)
        try writeMemo(
            address: newAddress,
            memo: memo
        )
        try deleteMemo(address)
        return newAddress
    }

    /// Update audience for memo.
    /// This moves memo from sphere to local or vise versa.
    func updateAudienceAsync(
        address: MemoAddress,
        audience: Audience
    ) -> AnyPublisher<MemoAddress, Error> {
        CombineUtilities.async {
            return try updateAudience(address: address, audience: audience)
        }
    }

    /// Move entry to a new location, updating file system and database.
    private func moveEntry(from: EntryLink, to: EntryLink) throws {
        guard from.address.slug != to.address.slug else {
            throw DataServiceError.fileExists(to.address.slug.description)
        }
        // Make sure we're writing to an empty location
        guard local.info(to.address.slug) == nil else {
            throw DataServiceError.fileExists(to.address.slug.description)
        }
        let fromMemo = try local.read(from.address.slug).unwrap()
        let fromFile = MemoEntry(address: from.address, contents: fromMemo)
        // Make a copy representing new location and set new title and slug
        var toFile = fromFile
        toFile.address = to.address
        // Write to new destination
        try writeEntry(toFile)
        // ...Then delete old entry
        try deleteMemo(fromFile.address)
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
        parent: EntryLink,
        child: EntryLink
    ) throws {
        let childEntry = MemoEntry(
            address: child.address,
            contents: try local.read(child.address.slug).unwrap()
        )
        
        let parentEntry = MemoEntry(
            address: parent.address,
            contents: try local.read(parent.address.slug).unwrap()
        )
        .merge(childEntry)
        
        //  First write the merged file to "to" location
        try writeEntry(parentEntry)
        //  Then delete child entry *afterwards*.
        //  We do this last to avoid data loss in case of write errors.
        try deleteMemo(childEntry.address)
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
            try mergeEntry(parent: parent, child: child)
        }
    }
    
    /// Update the title of an entry, without changing its slug
    private func retitleEntry(
        address: MemoAddress,
        title: String
    ) throws {
        var entry = MemoEntry(
            address: address,
            contents: try local.read(address.slug).unwrap()
        )
        entry.contents.title = title
        try writeEntry(entry)
    }
    
    /// Change title header of entry, without moving it.
    /// - Returns combine publisher
    func retitleEntryAsync(
        address: MemoAddress,
        title: String
    ) -> AnyPublisher<Void, Error> {
        CombineUtilities.async {
            try retitleEntry(address: address, title: title)
        }
    }
    
    func listRecentMemos() -> AnyPublisher<[EntryStub], Error> {
        CombineUtilities.async(qos: .default) {
            database.listRecentMemos()
        }
    }

    func countMemos() throws -> Int {
        return try database.countMemos().unwrap()
    }

    /// Count all entries
    func countMemos() -> AnyPublisher<Int, Error> {
        CombineUtilities.async(qos: .userInteractive) {
            try countMemos()
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
        omitting invalidSuggestions: Set<MemoAddress> = Set(),
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
    
    /// Given a slug, get back a resolved MemoAddress
    /// If there is public content, that will be returned.
    /// Otherwise, if there is local content, that will be returned.
    func findAddress(
        slug: Slug
    ) -> MemoAddress? {
        // If slug exists in default sphere, return that.
        if noosphere.getFileVersion(slashlink: slug.toSlashlink()) != nil {
            return MemoAddress(slug: slug, audience: .public)
        }
        // Otherwise if slug exists on local, return that.
        if local.info(slug) != nil {
            return MemoAddress(slug: slug, audience: .local)
        }
        return nil
    }

    private func readDetail(
        address: MemoAddress,
        title: String,
        fallback: String
    ) throws -> EntryDetail {
        let backlinks = database.readEntryBacklinks(slug: address.slug)

        let draft = EntryDetail(
            saveState: .draft,
            entry: Entry(
                address: address,
                contents: Memo(
                    contentType: ContentType.subtext.rawValue,
                    created: Date.now,
                    modified: Date.now,
                    title: title,
                    fileExtension: ContentType.subtext.fileExtension,
                    additionalHeaders: [],
                    body: fallback
                )
            )
        )

        switch address.audience {
        case .public:
            let slashlink = address.slug.toSlashlink()
            guard let memo = noosphere.read(
                slashlink: slashlink
            )?.toMemo() else {
                return draft
            }
            return EntryDetail(
                saveState: .saved,
                entry: Entry(
                    address: address,
                    contents: memo
                ),
                backlinks: backlinks
            )
        case .local:
            // Retreive top entry from file system to ensure it is fresh.
            // If no file exists, return a draft, using fallback for title.
            guard let memo = local.read(address.slug) else {
                return draft
            }
            // Return entry
            return EntryDetail(
                saveState: .saved,
                entry: Entry(
                    address: address,
                    contents: memo
                ),
                backlinks: backlinks
            )
        }
    }

    /// Get memo and backlinks from slug, using string as a fallback.
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a
    /// clean slug.
    func readDetailAsync(
        address: MemoAddress,
        title: String,
        fallback: String
    ) -> AnyPublisher<EntryDetail, Error> {
        CombineUtilities.async(qos: .utility) {
            try readDetail(address: address, title: title, fallback: fallback)
        }
    }
    
    /// Choose a random entry and publish slug
    func readRandomEntryLink() throws -> EntryLink {
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
