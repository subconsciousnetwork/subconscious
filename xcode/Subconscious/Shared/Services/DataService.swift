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
    case sphereExists(_ sphereIdentity: String)
    case cannotWriteToSphere(did: Did? = nil, petname: Petname? = nil)
    case unknownPetname(Petname)
    
    var errorDescription: String? {
        switch self {
        case .fileExists(let message):
            return "File exists: \(message)"
        case let .sphereExists(sphereIdentity):
            return "Sphere exists: \(sphereIdentity)"
        case let .cannotWriteToSphere(did, petname):
            let did = did?.description ?? "unknown"
            let petname = petname?.description ?? "unknown"
            return "Cannot write to sphere with did \(did) and petname \(petname)"
        case .unknownPetname(let petname):
            return "No sphere in index with petname \(petname)"
        }
    }
}

/// Receipt for a successful move transaction
struct MoveReceipt: Hashable {
    var from: Slashlink
    var to: Slashlink
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
    private var userProfile: UserProfileService
    private var local: HeaderSubtextMemoStore
    private var logger: Logger = logger

    init(
        noosphere: NoosphereService,
        database: DatabaseService,
        local: HeaderSubtextMemoStore,
        addressBook: AddressBookService,
        userProfile: UserProfileService
    ) {
        self.database = database
        self.noosphere = noosphere
        self.local = local
        self.addressBook = addressBook
        self.userProfile = userProfile
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
        logger.log(
            "User sphere created and persisted",
            metadata: [
                "ownerKeyName": ownerKeyName,
                "identity": sphereReceipt.identity.description
            ]
        )
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

    /// Index a peer sphere's content in our database.
    ///
    /// - If sphere has been indexed before, we retreive the last-indexed
    ///   version, and use it to get changes since.
    /// - If sphere has not been indexed, we get everything, and update
    func indexPeer(
        petname: Petname
    ) async throws -> PeerRecord {
        let sphere = try await noosphere.traverse(petname: petname)
        let identity = try await sphere.identity()
        logger.log(
            "Traversed to peer",
            metadata: [
                "petname": petname.description,
                "identity": identity.description,
            ]
        )
        let version = try await sphere.version()
        // Get peer info from last sync
        let peer = try? database.readPeer(petname: petname)
        // Get changes since the last time we indexed this peer,
        // or get all changes if this is the first time we've tried to index.
        let changes = try await sphere.changes(since: peer?.since)
        logger.log(
            "Indexing peer",
            metadata: [
                "petname": petname.description,
                "identity": identity.description,
                "version": version,
                "since": peer?.since ?? "nil",
                "changes": changes.count.description
            ]
        )
        
        let savepoint = "index_peer"
        try database.savepoint(savepoint)
        do {
            for change in changes {
                let slashlink = Slashlink(slug: change)
                // If memo does exist, write it to database.
                // If memo does not exist, that means change was a remove.
                if let memo = try? await sphere.read(
                    slashlink: slashlink
                ).toMemo() {
                    try database.writeMemo(
                        MemoRecord(
                            did: identity,
                            petname: petname,
                            slug: change,
                            memo: memo
                        )
                    )
                    logger.log(
                        "Indexed memo \(slashlink)",
                        metadata: [
                            "slashlink": slashlink.description
                        ]
                    )
                } else {
                    logger.log(
                        "Removed indexed memo \(slashlink)",
                        metadata: [
                            "slashlink": slashlink.description
                        ]
                    )
                    try database.removeMemo(
                        did: identity,
                        slug: change
                    )
                }
            }
            try database.writePeer(
                PeerRecord(
                    petname: petname,
                    identity: identity,
                    since: version
                )
            )
            try database.release(savepoint)
            logger.log(
                "Indexed peer",
                metadata: [
                    "petname": petname.description,
                    "identity": identity.description,
                    "version": version,
                    "since": peer?.since ?? "nil"
                ]
            )
        } catch {
            try database.rollback(savepoint)
            logger.log(
                "Failed to index peer. Rolling back.",
                metadata: [
                    "petname": petname.description,
                    "identity": identity.description,
                    "version": version,
                    "since": peer?.since ?? "nil"
                ]
            )
            throw error
        }
        return PeerRecord(
            petname: petname,
            identity: identity,
            since: version
        )
    }
    
    func indexPeers(petnames: [Petname]) async -> [PeerIndexResult] {
        var results: [PeerIndexResult] = []
        
        for petname in petnames {
            logger.log(
                "Indexing peer",
                metadata: [
                    "petname": petname.description
                ]
            )
            
            do {
                let peer = try await self.indexPeer(
                    petname: petname
                )
                
                results.append(.success(peer))
                // Give other tasks a chance to use noosphere, indexing many peers
                // can take a long time and potentially block user actions
                await Task.yield()
            } catch {
                results.append(
                    PeerIndexResult.failure(
                        PeerIndexError(
                            error: error.localizedDescription,
                            petname: petname
                        )
                    )
                )
            }
        }
        
        return results
    }
    
    func resetIndex() async throws {
        let did = try await self.noosphere.identity()
        try self.database.resetOurSphere(identity: did)
        try self.database.resetPeers()
    }

    /// Index our sphere's content in our database.
    ///
    /// The notion is that when our sphere's state advances (content and peers)
    /// we also atomically advance the state of the database.
    ///
    /// - If sphere has been indexed before, we retreive the last-indexed
    ///   version, and use it to get changes since.
    /// - If sphere has not been indexed, we get everything, and update
    ///
    /// If there is a failure, we roll back the database, so that the next
    /// time we try, it will pick back up from the previous `since`, and
    /// correctly replay everything since the last successful index.
    func indexOurSphere() async throws -> OurSphereRecord {
        let sphere = noosphere
        let identity = try await sphere.identity()
        let version = try await sphere.version()

        let since = try database.readOurSphere()?.since
        let savepoint = "index_our_sphere"
        // Save database state so we can roll back on error
        try database.savepoint(savepoint)

        do {
            // First index peers
            let peerChanges = try await noosphere.getPeerChanges(since: since)
            for change in peerChanges {
                switch change {
                case let .update(peer):
                    // If this peer has been indexed before, update the did
                    // (and correspondingly, the version, if needed) and write
                    // to database.
                    //
                    // If this peer is not been indexed before, write it to DB
                    // with nil version, since we have never yet indexed it.
                    if let existingPeer = try database.readPeer(
                        petname: peer.petname
                    ) {
                        let updatedPeer = existingPeer.update(
                            identity: peer.identity
                        )
                        try database.writePeer(updatedPeer)
                        logger.log(
                            "Updated record for peer",
                            metadata: [
                                "petname": updatedPeer.petname.description,
                                "identity": updatedPeer.identity.description,
                                "since": updatedPeer.since ?? "nil"
                            ]
                        )
                    } else {
                        let createdPeer = PeerRecord(
                            petname: peer.petname,
                            identity: peer.identity,
                            since: nil
                        )
                        // Intentionally set version to nil, since we have
                        // never yet indexed this peer.
                        try database.writePeer(createdPeer)
                        logger.log(
                            "Created record for peer",
                            metadata: [
                                "petname": createdPeer.petname.description,
                                "identity": createdPeer.identity.description,
                                "since": createdPeer.since ?? "nil"
                            ]
                        )
                    }
                case let .remove(petname):
                    // If we have a peer under this petname,
                    // purge its contents from the db.
                    if let removedPeer = try? database.readPeer(
                        petname: petname
                    ) {
                        try database.purgePeer(petname: removedPeer.petname)
                        logger.log(
                            "Purged peer",
                            metadata: [
                                "petname": removedPeer.petname.description,
                                "identity": removedPeer.identity.description,
                                "since": removedPeer.since ?? "nil"
                            ]
                        )
                    }
                }
            }
            
            // Give others a chance to do stuff for a bit.
            await Task.yield()
            
            // Then index memo changes from our sphere.
            let memoChanges = try await sphere.changes(since: since)
            for change in memoChanges {
                let slashlink = Slashlink(slug: change)
                // If memo does exist, write it to database.
                // If memo does not exist, that means change was a remove.
                if let memo = try? await sphere.read(
                    slashlink: slashlink
                ).toMemo() {
                    try database.writeMemo(
                        MemoRecord(
                            did: identity,
                            petname: nil,
                            slug: change,
                            memo: memo
                        )
                    )
                } else {
                    try database.removeMemo(
                        did: identity,
                        slug: change
                    )
                }
            }
            try database.writeOurSphere(
                OurSphereRecord(
                    identity: identity,
                    since: version
                )
            )
            try database.release(savepoint)
            logger.log(
                "Indexed our sphere",
                metadata: [
                    "identity": identity.description,
                    "version": version
                ]
            )
            
            return OurSphereRecord(
                identity: identity,
                since: version
            )
        } catch {
            try database.rollback(savepoint)
            logger.log(
                "Failed to index our sphere. Rolling back.",
                metadata: [
                    "identity": identity.description,
                    "version": version
                ]
            )
            throw error
        }
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
        ).filter({ change in
            switch change {
            case .same:
                return false
            default:
                return true
            }
        })
        for change in changes {
            // .leftOnly = create.
            // .leftNewer = update.
            // .rightNewer = Follower shouldn't be ahead.
            //               Leader wins.
            // .conflict = leader wins.
            // .rightOnly = delete. Remove from search index
            // .same = no change. Do nothing.
            switch change {
            case .leftOnly(let left), .leftNewer(let left, _), .rightNewer(let left, _), .conflict(let left, _):
                var memo = try local.read(left.slug).unwrap()
                // Read info from file system and set modified time
                let info = try local.info(left.slug).unwrap()
                memo.modified = info.modified
                try database.writeMemo(
                    MemoRecord(
                        did: Did.local,
                        petname: nil,
                        slug: left.slug,
                        memo: memo,
                        size: info.size
                    )
                )
            case .rightOnly(let right):
                try database.removeMemo(
                    did: Did.local,
                    slug: right.slug
                )
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
        address: Slashlink
    ) async throws -> Memo {
        guard !address.isLocal else {
            return try local.read(address.slug).unwrap()
        }
        let identity = try await noosphere.identity()
        return try await noosphere.read(
            slashlink: address.relativizeIfNeeded(did: identity)
        )
        .toMemo()
        .unwrap()
    }
    
    private func writeLocalMemo(
        slug: Slug,
        memo: Memo
    ) async throws {
        var memo = memo
        try local.write(slug, value: memo)
        // Read modified/size from file system directly after writing.
        // Why: we use file system as source of truth and don't want any
        // discrepencies to sneak in (e.g. different time between write and
        // persistence on file system).
        let info = try local.info(slug).unwrap()
        memo.modified = info.modified
        try database.writeMemo(
            MemoRecord(
                did: Did.local,
                petname: nil,
                slug: slug,
                memo: memo,
                size: info.size
            )
        )
    }

    private func writeSphereMemo(
        slug: Slug,
        memo: Memo
    ) async throws {
        let identity = try await noosphere.identity()
        // Get absolute slashlink
        let body = try memo.body.toData().unwrap()
        try await noosphere.write(
            slug: slug,
            contentType: memo.contentType,
            additionalHeaders: memo.headers,
            body: body
        )
        let version = try await noosphere.save()
        // Write to database
        try database.writeMemo(
            MemoRecord(
                did: identity,
                petname: nil,
                slug: slug,
                memo: memo
            )
        )
        // Write new sphere version to database
        try database.writeOurSphere(
            OurSphereRecord(
                identity: identity,
                since: version
            )
        )
    }

    /// Write entry to file system and database
    /// Also sets modified header to now.
    func writeMemo(
        address: Slashlink,
        memo: Memo
    ) async throws {
        var memo = memo
        memo.modified = Date.now
        
        switch address.peer {
        case .none:
            return try await writeSphereMemo(slug: address.slug, memo: memo)
        case let .did(did) where did == Did.local:
            return try await writeLocalMemo(slug: address.slug, memo: memo)
        case let .did(did):
            throw DataServiceError.cannotWriteToSphere(did: did)
        case let .petname(petname):
            throw DataServiceError.cannotWriteToSphere(petname: petname)
        }
    }
    
    func assignNoteColor(
        address: Slashlink,
        color: NoteColor
    ) async throws {
        var memo = try await readMemo(address: address)
        memo.color = color
        
        try await writeMemo(address: address, memo: memo)
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
    func deleteMemo(_ address: Slashlink) async throws {
        let identity = try await noosphere.identity()
        let did = try await noosphere.resolve(peer: address.peer)
        let slug = address.slug
        switch did {
        case Did.local:
            try local.remove(address.slug)
            try database.removeMemo(did: did, slug: slug)
            return
        case identity:
            try await noosphere.remove(slug: address.slug)
            let version = try await noosphere.save()
            try database.removeMemo(did: did, slug: slug)
            // Write new sphere version to database
            try database.writeOurSphere(
                OurSphereRecord(
                    identity: identity,
                    since: version
                )
            )
            return
        default:
            throw DataServiceError.cannotWriteToSphere(
                did: did,
                petname: address.petname
            )
        }
    }
    
    /// Delete entry from file system and database
    nonisolated func deleteMemoPublisher(
        _ address: Slashlink
    ) -> AnyPublisher<Void, Error> {
        Future.detached(priority: .utility) {
            try await self.deleteMemo(address)
        }
        .eraseToAnyPublisher()
    }
    
    /// Move entry to a new location, updating file system and database.
    func moveEntry(
        from: Slashlink,
        to: Slashlink
    ) async throws -> MoveReceipt {
        let identity = try await noosphere.identity()
        let from = from.relativizeIfNeeded(did: identity)
        let to = to.relativizeIfNeeded(did: identity)
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
        from: Slashlink,
        to: Slashlink
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
        parent: Slashlink,
        child: Slashlink
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
        parent: Slashlink,
        child: Slashlink
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.mergeEntry(parent: parent, child: child)
        }
        .eraseToAnyPublisher()
    }
    
    func listRecentMemos() async throws -> [EntryStub] {
        let identity = try? await noosphere.identity()
        return try self.database.listRecentMemos(owner: identity, includeDrafts: true)
    }
    
    nonisolated func listRecentMemosPublisher() -> AnyPublisher<[EntryStub], Error> {
        Future.detached {
            try await self.listRecentMemos()
        }
        .eraseToAnyPublisher()
    }
    
    func listFeed() async throws -> [EntryStub] {
        let identity = try await noosphere.identity()
        return try self.database.listFeed(owner: identity)
    }
    
    nonisolated func listFeedPublisher() -> AnyPublisher<[StoryEntry], Error> {
        Future.detached {
            let entries = try await self.listFeed()
            var authors: [Did:UserProfile] = [:]
            var stories: [StoryEntry] = []
            
            for entry in entries {
                // Have we already found the author for this post?
                if let author = authors[entry.did] {
                    stories.append(StoryEntry(entry: entry, author: author))
                    continue
                }
                
                let user = try await self.userProfile.identifyUser(
                    did: entry.did,
                    address: entry.address,
                    context: nil
                )
                
                authors.updateValue(user, forKey: entry.did)
                stories.append(StoryEntry(entry: entry, author: user))
            }
            
            return stories
        }
        .eraseToAnyPublisher()
    }
    
    func countMemos() async throws -> Int {
        let identity = try? await noosphere.identity()
        return try database.countMemos(owner: identity).unwrap()
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
            let identity = try? await self.noosphere.identity()
            return try await self.database.searchSuggestions(
                owner: identity,
                query: query
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Fetch search suggestions
    /// A whitespace query string will fetch zero-query suggestions.
    nonisolated func searchLinkSuggestionsPublisher(
        query: String,
        omitting invalidSuggestions: Set<Slashlink> = Set(),
        fallback: [LinkSuggestion] = []
    ) -> AnyPublisher<[LinkSuggestion], Error> {
        Future.detached(priority: .userInitiated) {
            let identity = try await self.noosphere.identity()
            return await self.database.searchLinkSuggestions(
                owner: identity,
                query: query,
                omitting: invalidSuggestions,
                fallback: fallback
            )
        }
        .eraseToAnyPublisher()
    }
    
    nonisolated func searchRenameSuggestionsPublisher(
        query: String,
        current: Slashlink
    ) -> AnyPublisher<[RenameSuggestion], Error> {
        Future.detached(priority: .userInitiated) {
            let identity = try? await self.noosphere.identity()
            return try await self.database.searchRenameSuggestions(
                owner: identity,
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
    func exists(_ address: Slashlink) async -> Bool {
        guard !address.isLocal else {
            let info = local.info(address.slug)
            return info != nil
        }
        let version = await noosphere.getFileVersion(
            slashlink: address
        )
        return version != nil
    }
    
    /// Given a slug, get back a resolved MemoAddress for our own sphere.
    /// If there is public content, that will be returned.
    /// Otherwise, if there is local content, that will be returned.
    func findAddressInOurs(
        slug: Slug
    ) async -> Slashlink? {
        let sphereAddress = slug.toSlashlink()
        // If slug exists in default sphere, return that.
        if await noosphere.getFileVersion(
            slashlink: sphereAddress
        ) != nil {
            return sphereAddress
        }
        // Otherwise if slug exists on local, return that.
        if local.info(slug) != nil {
            return slug.toLocalSlashlink()
        }
        return nil
    }
    
    nonisolated func findAddressInOursPublisher(
        slug: Slug
    ) -> AnyPublisher<Slashlink?, Never> {
        Future.detached {
            await self.findAddressInOurs(slug: slug)
        }
        .eraseToAnyPublisher()
    }
    
    func findUniqueAddressFor(
        _ text: String,
        audience: Audience
    ) async -> Slashlink? {
        // If we can't derive slug from text, exit early.
        guard let slug = Subtext.generateSlug(markup: text) else {
            return nil
        }
        // If slug does not exist in any address space, return it.
        if await findAddressInOurs(slug: slug) == nil {
            return slug.toSlashlink(audience: audience)
        }
        for n in 2..<500 {
            // If we can't derive slug from text, give up.
            guard let slugN = Slug("\(slug.description)-\(n)") else {
                return nil
            }
            if await findAddressInOurs(slug: slugN) == nil {
                return slugN.toSlashlink(audience: audience)
            }
        }
        return nil
    }
    
    nonisolated func findUniqueAddressForPublisher(
        _ text: String,
        audience: Audience
    ) -> AnyPublisher<Slashlink?, Never> {
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
    
    func readMemoBacklinks(
        address: Slashlink
    ) async throws -> [EntryStub] {
        let identity = try? await noosphere.identity()
        let did = try await noosphere.resolve(peer: address.peer)
        
        return try database.readEntryBacklinks(
            owner: identity,
            did: did,
            slug: address.slug
        )
    }

    /// Read editor detail for address.
    /// Addresses with petnames will throw an exception, since we don't
    /// have write access to others' spheres.
    /// - Returns a MemoEditorDetailResponse for the editor state.
    func readMemoEditorDetail(
        address: Slashlink,
        fallback: String
    ) async throws -> MemoEditorDetailResponse {
        let identity = try? await noosphere.identity()
        let did = try await noosphere.resolve(peer: address.peer)
        
        // We do not allow editing 3p memos.
        guard did.isLocal || did == identity else {
            throw DataServiceError.cannotWriteToSphere(
                did: did,
                petname: address.petname
            )
        }
        
        // Read memo from local or sphere.
        let memo = try? await readMemo(address: address)
        
        guard let memo = memo else {
            logger.log(
                "Memo does not exist at \(address). Returning new draft."
            )
            return MemoEditorDetailResponse(
                saveState: .unsaved,
                entry: Entry(
                    address: address,
                    contents: Memo.draft(body: fallback)
                )
            )
        }
        
        return MemoEditorDetailResponse(
            saveState: .saved,
            entry: Entry(
                address: address,
                contents: memo
            )
        )
    }

    /// Get memo and backlinks from slug, using string as a fallback.
    /// We trust caller to slugify the string, if necessary.
    /// Allowing any string allows us to retreive files that don't have a
    /// clean slug.
    nonisolated func readMemoEditorDetailPublisher(
        address: Slashlink,
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
        address: Slashlink
    ) async -> MemoEntry? {
        // Read memo from local or sphere.
        guard let memo = try? await readMemo(
            address: address
        ) else {
            return nil
        }
        
        return MemoEntry(
            address: address,
            contents: memo
        )
    }

    /// Read view-only memo detail for address.
    /// - Returns publisher for `MemoDetailResponse` or error
    nonisolated func readMemoDetailPublisher(
        address: Slashlink
    ) -> AnyPublisher<MemoEntry?, Never> {
        Future.detached {
            await self.readMemoDetail(address: address)
        }
        .eraseToAnyPublisher()
    }

    /// Choose a random entry and publish slug
    func readRandomEntryLink() async throws -> EntryLink {
        guard let identity = try? await noosphere.identity() else {
            throw DatabaseServiceError.randomEntryFailed
        }
        
        guard let link = database.readRandomEntryLink(owner: identity) else {
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
