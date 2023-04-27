//
//  DataService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/22/23.
//
import Foundation
import Combine
import os

enum DataServiceError: Error, LocalizedError {
    case fileExists(String)
    case defaultSphereNotFound
    case sphereExists(_ sphereIdentity: String)
    case permissionsError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileExists(let message):
            return "File exists: \(message)"
        case .defaultSphereNotFound:
            return "Default sphere not found"
        case let .sphereExists(sphereIdentity):
            return "Sphere exists: \(sphereIdentity)"
        case let .permissionsError(message):
            return "Permissions error: \(message)"
        }
    }
}

/// Record of a successful move transaction
struct MoveReceipt: Hashable {
    var from: MemoAddress
    var to: MemoAddress
}

// MARK: SERVICE
/// Wraps both database and source-of-truth store, providing data
/// access methods for the app.
actor DataService {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DataService"
    )
    
    private var addressBook: AddressBookService
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var local: HeaderSubtextMemoStore
    private var logger: Logger = logger

    init(
        noosphere: NoosphereService,
        database: DatabaseService,
        local: HeaderSubtextMemoStore,
        addressBook: AddressBookService
    ) {
        self.database = database
        self.noosphere = noosphere
        self.local = local
        self.addressBook = addressBook
    }
    
    /// Create a default sphere for user if needed, and persist sphere details.
    /// - Returns: SphereReceipt
    /// Will not create sphere if a sphereIdentity already appears in
    /// the user defaults.
    func createSphere(ownerKeyName: String) async throws -> SphereReceipt {
        // Do not create sphere if one already exists
        if let sphereIdentity = AppDefaults.standard.sphereIdentity {
            throw DataServiceError.sphereExists(sphereIdentity)
        }
        let sphereReceipt = try await noosphere.createSphere(
            ownerKeyName: ownerKeyName
        )
        // Persist sphere identity to user defaults.
        // NOTE: we do not persist the mnemonic, since it would be insecure.
        // Instead, we return the receipt so that mnemonic can be displayed
        // and discarded.
        AppDefaults.standard.sphereIdentity = sphereReceipt.identity
        // Set sphere identity on NoosphereService
        await noosphere.resetSphere(sphereReceipt.identity)
        return sphereReceipt
    }
    
    /// Migrate database off main thread, returning a publisher
    nonisolated func migratePublisher() -> AnyPublisher<Int, Error> {
        Future.detached(priority: .utility) {
            try await self.database.migrate()
        }
        .eraseToAnyPublisher()
    }
    
    /// Rebuild database and re-sync everything.
    nonisolated func rebuildPublisher() -> AnyPublisher<Int, Error> {
        Future.detached(priority: .utility) {
            try await self.database.rebuild()
        }
        .eraseToAnyPublisher()
    }
    
    func syncSphereWithDatabase() async throws -> String {
        let identity = try await noosphere.identity()
        let version = try await noosphere.version()
        let since = try? database.readSphereSyncInfo(sphereIdentity: identity)
        let changes = try await noosphere.changes(since: since)
        for change in changes {
            let address = change.toPublicMemoAddress()
            let slashlink = address.toSlashlink()
            // If memo does exist, write it to database
            // Sphere content is always public right now
            if let memo = try? await noosphere.read(
                slashlink: slashlink
            ).toMemo() {
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
        try database.writeSphereSyncInfo(
            sphereIdentity: identity,
            version: version
        )
        return version
    }
    
    nonisolated func syncSphereWithDatabasePublisher() -> AnyPublisher<String, Error> {
        Future.detached(priority: .utility) {
            try await self.syncSphereWithDatabase()
        }
        .eraseToAnyPublisher()
    }

    /// Sync the contents of a specific sphere to the database
    func syncSphereWithDatabase(petname: Petname) async throws -> String {
        let sphere = try await noosphere.traverse(petname: petname)
        let identity = try await sphere.identity()
        let version = try await sphere.version()
        // TODO: must be since last known database-recorded version.
        let changes = try await sphere.changes(since: version)
        for change in changes {
            let slashlink = change.toSlashlink(relativeTo: petname)
            let address = slashlink.toPublicMemoAddress()
            // If memo does exist, write it to database
            if let memo = try? await noosphere.read(
                slashlink: slashlink
            ).toMemo() {
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
        // TODO: write to database
        return version
    }

    /// Sync file system with database.
    /// Note file system is source-of-truth (leader).
    /// Syncing will never delete files on the file system.
    func syncLocalWithDatabase() throws -> [FileFingerprintChange] {
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
                    left.slug.toLocalMemoAddress(),
                    memo: memo,
                    size: info.size
                )
                // .rightOnly = delete. Remove from search index
            case .rightOnly(let right):
                try database.removeMemo(
                    right.slug.toLocalMemoAddress()
                )
                // .same = no change. Do nothing.
            case .same:
                break
            }
        }
        return changes
    }
    
    nonisolated func syncLocalWithDatabasePublisher() -> AnyPublisher<[FileFingerprintChange], Error> {
        Future.detached(priority: .utility) {
            try await self.syncLocalWithDatabase()
        }
        .eraseToAnyPublisher()
    }
    
    /// Read memo from sphere or local
    func readMemo(
        address: MemoAddress
    ) async throws -> Memo {
        switch address {
        case .public(let slashlink):
            return try await noosphere.read(slashlink: slashlink)
                .toMemo()
                .unwrap()
        case .local(let slug):
            return try local.read(slug).unwrap()
        }
    }
    
    /// Write entry to file system and database
    /// Also sets modified header to now.
    func writeMemo(
        address: MemoAddress,
        memo: Memo
    ) async throws {
        var memo = memo
        memo.modified = Date.now
        
        switch address {
        case .public(let slashlink):
            let body = try memo.body.toData().unwrap()
            try await noosphere.write(
                slug: slashlink.slug,
                contentType: memo.contentType,
                additionalHeaders: memo.headers,
                body: body
            )
            let version = try await noosphere.save()
            // Write to database
            try database.writeMemo(
                address,
                memo: memo
            )
            let identity = try await noosphere.identity()
            // Write new sphere version to database
            try database.writeSphereSyncInfo(
                sphereIdentity: identity,
                version: version
            )
            return
        case .local(let slug):
            try local.write(slug, value: memo)
            // Read modified/size from file system directly after writing.
            // Why: we use file system as source of truth and don't want any
            // discrepencies to sneak in (e.g. different time between write and
            // persistence on file system).
            let info = try local.info(slug).unwrap()
            memo.modified = info.modified
            try database.writeMemo(
                address,
                memo: memo,
                size: info.size
            )
            return
        }
    }
    
    func writeEntry(_ entry: MemoEntry) async throws {
        try await writeMemo(address: entry.address, memo: entry.contents)
    }
    
    nonisolated func writeEntryPublisher(
        _ entry: MemoEntry
    ) -> AnyPublisher<Void, Error> {
        Future.detached(priority: .utility) {
            try await self.writeEntry(entry)
        }
        .eraseToAnyPublisher()
    }
    
    /// Delete entry from file system and database
    func deleteMemo(_ address: MemoAddress) async throws {
        switch address {
        case .local(let slug):
            try local.remove(slug)
            try database.removeMemo(address)
            return
        case .public(let slashlink):
            try await noosphere.remove(slug: slashlink.slug)
            let version = try await noosphere.save()
            try database.removeMemo(address)
            let identity = try await noosphere.identity()
            // Write new sphere version to database
            try database.writeSphereSyncInfo(
                sphereIdentity: identity,
                version: version
            )
            return
        }
    }
    
    /// Delete entry from file system and database
    nonisolated func deleteMemoPublisher(
        _ address: MemoAddress
    ) -> AnyPublisher<Void, Error> {
        Future.detached(priority: .utility) {
            try await self.deleteMemo(address)
        }
        .eraseToAnyPublisher()
    }
    
    /// Move entry to a new location, updating file system and database.
    func moveEntry(
        from: MemoAddress,
        to: MemoAddress
    ) async throws -> MoveReceipt {
        guard from != to else {
            throw DataServiceError.fileExists(to.description)
        }
        guard await !self.exists(to) else {
            throw DataServiceError.fileExists(to.description)
        }
        let fromMemo = try await readMemo(address: from)
        // Make a copy representing new location and set new title and slug
        let toMemo = fromMemo
        // Write to new destination
        try await writeMemo(address: to, memo: toMemo)
        // ...Then delete old entry
        try await deleteMemo(from)
        return MoveReceipt(from: from, to: to)
    }
    
    /// Move entry to a new location, updating file system and database.
    /// - Returns a combine publisher
    nonisolated func moveEntryPublisher(
        from: MemoAddress,
        to: MemoAddress
    ) -> AnyPublisher<MoveReceipt, Error> {
        Future.detached {
            try await self.moveEntry(from: from, to: to)
        }
        .eraseToAnyPublisher()
    }
    
    /// Merge child entry into parent entry.
    /// - Appends `child` to `parent`
    /// - Writes the combined content to `parent`
    /// - Deletes `child`
    func mergeEntry(
        parent: MemoAddress,
        child: MemoAddress
    ) async throws {
        let childMemo = try await readMemo(address: child)
        let parentMemo = try await readMemo(address: parent)
        let mergedMemo = parentMemo.merge(childMemo)
        //  First write the merged file to "to" location
        try await writeMemo(address: parent, memo: mergedMemo)
        //  Then delete child entry *afterwards*.
        //  We do this last to avoid data loss in case of write errors.
        try await deleteMemo(child)
    }
    
    /// Merge child entry into parent entry.
    /// - Appends `child` to `parent`
    /// - Writes the combined content to `parent`
    /// - Deletes `child`
    /// - Returns combine publisher
    nonisolated func mergeEntryPublisher(
        parent: MemoAddress,
        child: MemoAddress
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.mergeEntry(parent: parent, child: child)
        }
        .eraseToAnyPublisher()
    }
    
    func listRecentMemos() async throws -> [EntryStub] {
        let recent = try self.database.listRecentMemos()
        return recent.filter { entry in
            !entry.address.slug.isHidden
        }
    }
    
    nonisolated func listRecentMemosPublisher() -> AnyPublisher<[EntryStub], Error> {
        Future.detached {
            try await self.listRecentMemos()
        }
        .eraseToAnyPublisher()
    }
    
    func countMemos() throws -> Int {
        return try database.countMemos().unwrap()
    }
    
    /// Count all entries
    nonisolated func countMemosPublisher() -> AnyPublisher<Int, Error> {
        Future.detached {
            try await self.countMemos()
        }
        .eraseToAnyPublisher()
    }
    
    nonisolated func searchSuggestionsPublisher(
        query: String
    ) -> AnyPublisher<[Suggestion], Error> {
        Future.detached(priority: .userInitiated) {
            try await self.database.searchSuggestions(query: query)
        }
        .eraseToAnyPublisher()
    }
    
    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    nonisolated func searchLinkSuggestionsPublisher(
        query: String,
        omitting invalidSuggestions: Set<MemoAddress> = Set(),
        fallback: [LinkSuggestion] = []
    ) -> AnyPublisher<[LinkSuggestion], Error> {
        Future.detached(priority: .userInitiated) {
            await self.database.searchLinkSuggestions(
                query: query,
                omitting: invalidSuggestions,
                fallback: fallback
            )
        }
        .eraseToAnyPublisher()
    }
    
    nonisolated func searchRenameSuggestionsPublisher(
        query: String,
        current: MemoAddress
    ) -> AnyPublisher<[RenameSuggestion], Error> {
        Future.detached(priority: .userInitiated) {
            try await self.database.searchRenameSuggestions(
                query: query,
                current: current
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Log a search query in search history db
    nonisolated func createSearchHistoryItemPublisher(
        query: String
    ) -> AnyPublisher<String, Error> {
        Future.detached(priority: .utility) {
            await self.database.createSearchHistoryItem(query: query)
        }
        .eraseToAnyPublisher()
    }
    
    /// Check if a given address exists
    func exists(_ address: MemoAddress) async -> Bool {
        switch address {
        case .public(let slashlink):
            let version = await noosphere.getFileVersion(
                slashlink: slashlink
            )
            return version != nil
        case .local(let slug):
            let info = local.info(slug)
            return info != nil
        }
    }
    
    /// Given a slug, get back a resolved MemoAddress for our own sphere.
    /// If there is public content, that will be returned.
    /// Otherwise, if there is local content, that will be returned.
    func findAddressInOurs(
        slug: Slug
    ) async -> MemoAddress? {
        // If slug exists in default sphere, return that.
        if await noosphere.getFileVersion(
            slashlink: slug.toSlashlink()
        ) != nil {
            return slug.toPublicMemoAddress()
        }
        // Otherwise if slug exists on local, return that.
        if local.info(slug) != nil {
            return slug.toLocalMemoAddress()
        }
        return nil
    }
    
    nonisolated func findAddressInOursPublisher(
        slug: Slug
    ) -> AnyPublisher<MemoAddress?, Never> {
        Future.detached {
            await self.findAddressInOurs(slug: slug)
        }
        .eraseToAnyPublisher()
    }
    
    func findUniqueAddressFor(
        _ text: String,
        audience: Audience
    ) async -> MemoAddress? {
        let excerpt = Subtext.excerpt(markup: text, fallback: text)
        
        // If we can't derive slug from text, exit early.
        guard let slug = Slug(formatting: excerpt) else {
            return nil
        }
        // If slug does not exist in any address space, return it.
        if await findAddressInOurs(slug: slug) == nil {
            return slug.toMemoAddress(audience)
        }
        for n in 2..<500 {
            // If we can't derive slug from text, give up.
            guard let slugN = Slug("\(slug.description)-\(n)") else {
                return nil
            }
            if await findAddressInOurs(slug: slugN) == nil {
                return slugN.toMemoAddress(audience)
            }
        }
        return nil
    }
    
    nonisolated func findUniqueAddressForPublisher(
        _ text: String,
        audience: Audience
    ) -> AnyPublisher<MemoAddress?, Never> {
        Future.detached {
            await self.findUniqueAddressFor(text, audience: audience)
        }
        .eraseToAnyPublisher()
    }

    private func readSphereMemo(
        slashlink: Slashlink
    ) async -> Memo? {
        try? await noosphere.read(slashlink: slashlink).toMemo()
    }

    /// Read memo from local store
    private func readLocalMemo(
        slug: Slug
    ) async -> Memo? {
        local.read(slug)
    }

    /// Read editor detail for address.
    /// Addresses with petnames will throw an exception, since we don't
    /// have write access to others' spheres.
    /// - Returns a MemoEditorDetailResponse for the editor state.
    func readMemoEditorDetail(
        address: MemoAddress,
        fallback: String
    ) async throws -> MemoEditorDetailResponse {
        // We do not allow editing 3p memos. Throw.
        if !address.isOurs {
            throw DataServiceError.permissionsError(
                "Cannot edit memo `\(address)"
            )
        }
        // Read memo from local or sphere.
        let memo = await Func.run {
            switch address {
            case .local(let slug):
                return await readLocalMemo(slug: slug)
            
            case .public(let slashlink):
                return await readSphereMemo(slashlink: slashlink)
            }
        }

        let backlinks = database.readEntryBacklinks(slug: address.slug)

        guard let memo = memo else {
            logger.log(
                "Memo does not exist at \(address). Returning new draft."
            )
            return MemoEditorDetailResponse(
                saveState: .unsaved,
                entry: Entry(
                    address: address,
                    contents: Memo.draft(body: fallback)
                ),
                backlinks: backlinks
            )
        }

        return MemoEditorDetailResponse(
            saveState: .saved,
            entry: Entry(
                address: address,
                contents: memo
            ),
            backlinks: backlinks
        )
    }

    /// Get memo and backlinks from slug, using string as a fallback.
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a
    /// clean slug.
    nonisolated func readMemoEditorDetailPublisher(
        address: MemoAddress,
        fallback: String
    ) -> AnyPublisher<MemoEditorDetailResponse, Error> {
        Future.detached {
            try await self.readMemoEditorDetail(
                address: address,
                fallback: fallback
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Read view-only memo detail for address.
    /// - Returns `MemoDetailResponse`
    func readMemoDetail(
        address: MemoAddress
    ) async -> MemoDetailResponse? {
        // Read memo from local or sphere.
        let memo = await Func.run {
            switch address {
            case .local(let slug):
                return await readLocalMemo(slug: slug)
            case .public(let slashlink):
                return await readSphereMemo(slashlink: slashlink)
            }
        }

        guard let memo = memo else {
            return nil
        }

        let backlinks = database.readEntryBacklinks(slug: address.slug)

        return MemoDetailResponse(
            entry: MemoEntry(
                address: address,
                contents: memo
            ),
            backlinks: backlinks
        )
    }

    /// Read view-only memo detail for address.
    /// - Returns publisher for `MemoDetailResponse` or error
    nonisolated func readMemoDetailPublisher(
        address: MemoAddress
    ) -> AnyPublisher<MemoDetailResponse?, Never> {
        Future.detached {
            await self.readMemoDetail(address: address)
        }
        .eraseToAnyPublisher()
    }

    /// Choose a random entry and publish slug
    func readRandomEntryLink() throws -> EntryLink {
        guard let link = database.readRandomEntryLink() else {
            throw DatabaseServiceError.randomEntryFailed
        }
        return link
    }

    /// Choose a random entry and publish slug
    nonisolated func readRandomEntryLinkPublisher() -> AnyPublisher<EntryLink, Error> {
        Future.detached {
            try await self.readRandomEntryLink()
        }
        .eraseToAnyPublisher()
    }
}
