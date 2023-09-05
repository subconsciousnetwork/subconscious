//
//  AddressBookService.swift
//  Subconscious
//
//  Created by Ben Follington on 14/3/2023.
//

import os
import Foundation
import Combine

struct AddressBookEntry: Equatable, Hashable, Codable {
    let petname: Petname
    let did: Did
    let status: ResolutionStatus
    let version: Cid
    
    var name: Petname.Name {
        petname.root
    }
}

enum AddressBookError: Error {
    case cannotFollowYourself
    case alreadyFollowing
    case failedToIncrementPetname
    case exhaustedUniquePetnameRange
    case invalidAttemptToOverwitePetname
    case other(String)
}

extension AddressBookError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cannotFollowYourself:
            return String(
                localized: "You cannot follow yourself.",
                comment: "Address Book error description"
            )
        case .alreadyFollowing:
            return String(
                localized: "You are already following {}.",
                comment: "Address Book error description"
            )
        case .failedToIncrementPetname:
            return String(
                localized: "Failed to increment a petname's suffix.",
                comment: "Address Book error description"
            )
        case .exhaustedUniquePetnameRange:
            return String(
                localized: "Failed to find an available petname.",
                comment: "Address Book error description"
            )
        case .invalidAttemptToOverwitePetname:
            return String(
                localized: "Petname already in use.",
                comment: "Address Book error description"
            )
        case .other(let msg):
            return String(
                localized: "An unknown error occurred: \(msg)",
                comment: "Unknown Address Book error description"
            )
        }
    }
}

/// An AddressBook can wrap any Sphere and provide a higher-level interface to manage petnames.
actor AddressBook<Sphere: SphereProtocol> {
    private var sphere: Sphere
    
    private var cacheVersion: Cid?
    private var cache: [AddressBookEntry] = []
    
    /// Logger cannot be static because actor is generic
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddressBookService"
    )
    
    init(sphere: Sphere, addressBook: [AddressBookEntry] = []) {
        self.sphere = sphere
        self.cache = addressBook
    }
    
    /// Get the full list of entries in the address book.
    /// If an error occurs producing the entries the resulting list will be empty.
    func listEntries() async throws -> [AddressBookEntry] {
        let version = try await sphere.version()
        
        if let cachedVersion = self.cacheVersion,
           version == cachedVersion {
            return self.cache
        }
        
        var entries: [AddressBookEntry] = []
        
        let petnames = try await sphere.listPetnames()
        for petname in petnames {
            let did = try await sphere.getPetname(petname: petname)
            let status = await Func.run {
                do {
                    let cid =  try await sphere.resolvePetname(petname: petname)
                    return ResolutionStatus.resolved(cid)
                } catch {
                    return ResolutionStatus.unresolved
                }
            }
            let entry = AddressBookEntry(
                petname: petname,
                did: did,
                status: status,
                version: version
            )
            
            entries.append(entry)
        }
        
        // Maintain consistent order
        entries.sort { a, b in
            a.name < b.name
        }
        
        self.cache = entries
        self.cacheVersion = version
        return entries
    }

    /// Get the full list of entries in the address book.
    /// If an error occurs producing the entries the resulting list will be empty.
    nonisolated func listEntriesPublisher() -> AnyPublisher<[AddressBookEntry], Error> {
        Future.detached {
            try await self.listEntries()
        }
        .eraseToAnyPublisher()
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    func hasEntryForPetname(petname: Petname) async -> Bool {
        do {
            _  = try await self.sphere.getPetname(petname: petname)
            return true
        } catch {
            logger.error(
                """
                An error occurred checking for \(petname.markup), returning false. \
                Reason: \(error.localizedDescription)
                """
            )
            return false
        }
    }

    /// Is this user in the AddressBook?
    func isFollowingUser(did: Did) async throws -> Bool {
        let entries = try await listEntries()
        
        return entries.contains(where: { entry in
            entry.did == did
        })
    }
    
    /// Iteratively add a numerical suffix to petnames until we find an available alias.
    /// This can fail if `AddressBookService.maxAttemptsToIncrementPetName` iterations occur without
    /// finding a candidate.
    func findAvailablePetname(name: Petname.Name) async throws -> Petname.Name {
        var name = name
        var count = 0
        
        while await hasEntryForPetname(petname: name.toPetname()) {
            guard let next = name.increment() else {
                throw AddressBookError.exhaustedUniquePetnameRange
            }
           
            name = next
            count += 1
            
            // Escape hatch, no infinite loops plz
            if count > AddressBookService.maxAttemptsToIncrementPetName {
                throw AddressBookError.exhaustedUniquePetnameRange
            }
        }
        
        return name
    }
    
    func getPetname(petname: Petname) async throws -> Did? {
        return try? await self.sphere.getPetname(petname: petname)
    }

    nonisolated func getPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Did?, Error> {
        Future.detached(priority: .utility) {
            try await self.getPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func setPetname(did: Did, petname: Petname) async throws {
        try await sphere.setPetname(did: did, petname: petname)
    }

    nonisolated func setPetnamePublisher(
        did: Did,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
          try await self.setPetname(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func unsetPetname(petname: Petname) async throws {
        try await sphere.setPetname(did: nil, petname: petname)
    }

    nonisolated func unsetPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detached(priority: .utility) {
          try await self.unsetPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func listPetnames() async throws -> [Petname] {
        try await sphere.listPetnames()
    }

    func listPetnamesPublisher() -> AnyPublisher<[Petname], Error> {
        Future.detached(priority: .utility) {
          try await self.listPetnames()
        }
        .eraseToAnyPublisher()
    }

    func getPetnameChanges(since cid: Cid) async throws -> [Petname] {
        return try await sphere.getPetnameChanges(since: cid)
    }
      
    func getPetnameChangesPublisher(since cid: Cid) -> AnyPublisher<[Petname], Error> {
        Future.detached(priority: .utility) {
            try await self.getPetnameChanges(since: cid)
        }
        .eraseToAnyPublisher()
    }
    
    func listAliases(did: Did) async throws -> [Petname] {
        let entries = try await self.listEntries()
        
        return entries
            .filter { entry in
                entry.did == did
            }
            .map { entry in
                entry.name.toPetname()
            }
    }
    
    func followingStatus(did: Did, expectedName: Petname.Name?) async -> UserProfileFollowStatus {
        do {
            let found = try await listEntries()
                .filter { entry in
                    entry.did == did && (expectedName == nil || entry.name == expectedName)
                }
                .first
            
            guard let found = found else {
                return .notFollowing
            }
            
            return .following(found.name)
        } catch {
            logger.warning("Failed to check following status.")
            return .notFollowing
        }
    }
}

/// AddressBookService wraps an AddressBook around NoosphereService and keeps
/// the database in-sync with any follow / unfollows.
actor AddressBookService {
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: AddressBook<NoosphereService>
    
    private var pendingFollows: [Petname] = []
    
    var localAddressBook: AddressBook<NoosphereService> {
        addressBook
    }
    
    /// must be defined here not on `AddressBook` because
    /// `AddressBook` is generic and cannot hold static properties
    static let maxAttemptsToIncrementPetName = 99
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddressBookService"
    )
    
    init(noosphere: NoosphereService, database: DatabaseService) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = AddressBook(sphere: noosphere)
    }
    
    /// Get the full list of entries in the address book.
    /// If an error occurs producing the entries the resulting list will be empty.
    func listEntries() async throws -> [AddressBookEntry] {
        return try await self.addressBook.listEntries()
    }

    /// Get the full list of entries in the address book.
    /// If an error occurs producing the entries the resulting list will be empty.
    nonisolated func listEntriesPublisher() -> AnyPublisher<[AddressBookEntry], Error> {
        Future.detached {
            try await self.addressBook.listEntries()
        }
        .eraseToAnyPublisher()
    }
    
    /// Associates the passed DID with the passed petname within the sphere,
    /// saves the changes and updates the database.
    func followUser(
        did: Did,
        petname: Petname,
        preventOverwrite: Bool = false
    ) async throws {
        let ourIdentity = try await noosphere.identity()
        if ourIdentity.id == did.id {
            throw AddressBookError.cannotFollowYourself
        }
        
        let hasEntry = await self.addressBook.hasEntryForPetname(petname: petname)
        if preventOverwrite && hasEntry {
            throw AddressBookError.invalidAttemptToOverwitePetname
        }
        
        try await noosphere.setPetname(did: did, petname: petname)
        let version = try await noosphere.save()
        try database.writeOurSphere(
            OurSphereRecord(
                identity: ourIdentity,
                since: version
            )
        )
    }
    
    func resolutionStatus(petname: Petname) async throws -> ResolutionStatus {
        if self.pendingFollows.contains(petname) {
            return .pending
        }
        
        guard let record = try await self.listEntries()
            .first(where: { entry in entry.petname == petname }) else {
            return .unresolved
        }
        
        return record.status
    }
    
    func waitForPetnameResolution(
        petname: Petname
    ) async throws -> Cid? {
        let maxAttempts = 13 // 1+2+4+8+16+32+32+32+32+32+32+32+32 = 287 seconds
        
        self.pendingFollows.append(petname)
        
        let cid = try await Func.retryWithBackoff(maxAttempts: maxAttempts) { attempts in
            Self.logger.log("""
            Check for petname resolution, \
            attempt \(attempts) of \(maxAttempts)
            """)
            
            _ = try await self.noosphere.sync()
            do {
                _ = try await self.noosphere.getPetname(petname: petname)
            } catch {
                // Stop waiting, the petname is not in our addressbook anymore (unfollowed)
                throw RetryError.cancelled
            }
            
            return try await self.noosphere.resolvePetname(petname: petname)
        }
        
        self.pendingFollows.removeAll { f in f == petname }
        
        return cid
    }
    
    nonisolated func waitForPetnameResolutionPublisher(
        petname: Petname
    ) -> AnyPublisher<Cid?, Error> {
        Future.detached {
            try await self.waitForPetnameResolution(
                petname: petname
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Associates the passed DID with the passed petname within the sphere,
    /// saves the changes and updates the database.
    nonisolated func followUserPublisher(
        did: Did,
        petname: Petname,
        preventOverwrite: Bool = false
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.followUser(
                did: did,
                petname: petname,
                preventOverwrite: preventOverwrite
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Disassociates the passed Petname from any DID within the sphere,
    /// saves the changes and updates the database.
    func unfollowUser(petname: Petname) async throws -> Did {
        let ourIdentity = try await noosphere.identity()
        let did = try await self.noosphere.getPetname(petname: petname)
        try await self.addressBook.unsetPetname(petname: petname)
        let version = try await self.noosphere.save()
        try database.writeOurSphere(
            OurSphereRecord(
                identity: ourIdentity,
                since: version
            )
        )
        return did
    }
    
    /// Unassociates the passed petname with any DID in the sphere,
    /// saves the changes and updates the database.
    nonisolated func unfollowUserPublisher(
        petname: Petname
    ) -> AnyPublisher<Did, Error> {
        Future.detached {
            try await self.unfollowUser(petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func getPetname(petname: Petname) async throws -> Did? {
        try await self.noosphere.getPetname(petname: petname)
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    func hasEntryForPetname(petname: Petname) async -> Bool {
        await self.addressBook.hasEntryForPetname(petname: petname)
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    nonisolated func hasEntryForPetnamePublisher(petname: Petname) -> AnyPublisher<Bool, Never> {
        Future.detached {
            await self.addressBook.hasEntryForPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Iteratively add a numerical suffix to petnames until we find an available alias.
    /// This can fail if `maxAttemptsToIncrementPetName` iterations occur without
    /// finding a candidate.
    func findAvailablePetname(name: Petname.Name) async throws -> Petname.Name {
        try await self.addressBook.findAvailablePetname(name: name)
    }
    
    /// Iteratively add a numerical suffix to petnames until we find an available alias.
    /// This can fail if `maxAttemptsToIncrementPetName` iterations occur without
    /// finding a candidate.
    nonisolated func findAvailablePetnamePublisher(
        name: Petname.Name
    ) -> AnyPublisher<Petname.Name, Error> {
        Future.detached {
            try await self.addressBook.findAvailablePetname(name: name)
        }
        .eraseToAnyPublisher()
    }
    
    /// Is this user in the AddressBook?
    func followingStatus(did: Did, expectedName: Petname.Name?) async -> UserProfileFollowStatus {
        await self.addressBook.followingStatus(did: did, expectedName: expectedName)
    }
    
    func listAliases(did: Did) async throws -> [Petname] {
        try await self.addressBook.listAliases(did: did)
    }
    
    /// Is this user in the AddressBook?
    nonisolated func followingStatusPublisher(
        did: Did,
        expectedName: Petname.Name?
    ) -> AnyPublisher<UserProfileFollowStatus, Error> {
        Future.detached {
            await self.addressBook.followingStatus(did: did, expectedName: expectedName)
        }
        .eraseToAnyPublisher()
    }
}
