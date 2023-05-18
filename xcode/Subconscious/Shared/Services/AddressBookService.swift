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
    var nickname: PetnamePart
    var did: Did
    var status: ResolutionStatus
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
                localized: "This petname is already in use.",
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
    private var addressBook: [AddressBookEntry]?
    
    /// Logger cannot be static because actor is generic
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddressBookService"
    )
    
    init(sphere: Sphere, addressBook: [AddressBookEntry]? = nil) {
        self.sphere = sphere
        self.addressBook = addressBook
    }
    
    func invalidateCache() {
        addressBook = nil
    }
    
    /// Get the full list of entries in the address book.
    /// This is cached after the first use unless requested using refetch.
    /// If an error occurs producing the entries the resulting list will be empty.
    func listEntries(
        refetch: Bool = false
    ) async throws -> [AddressBookEntry] {
        if let addressBook = addressBook {
            if !refetch {
                return addressBook
            }
        }
        var addressBook: [AddressBookEntry] = []
        let petnames = try await sphere.listPetnames()
        for petname in petnames {
            let did = try await sphere.getPetname(petname: petname)
            let status = await Func.run {
                do {
                    let cid =  try await sphere.resolvePetname(petname: petname.toPetname())
                    return ResolutionStatus.resolved(cid)
                } catch {
                    return ResolutionStatus.unresolved
                }
            }
            
            addressBook.append(
                AddressBookEntry(
                    nickname: petname,
                    did: did,
                    status: status
                )
            )
        }
        
        // Maintain consistent order
        addressBook.sort { a, b in
            a.nickname < b.nickname
        }
        
        self.addressBook = addressBook
        return addressBook
    }

    /// Get the full list of entries in the address book.
    /// This is cached after the first use unless requested using refetch.
    /// If an error occurs producing the entries the resulting list will be empty.
    nonisolated func listEntriesPublisher(
        refetch: Bool = false
    ) -> AnyPublisher<[AddressBookEntry], Error> {
        Future.detached {
            try await self.listEntries(refetch: refetch)
        }
        .eraseToAnyPublisher()
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    func hasEntryForPetname(petname: PetnamePart) async -> Bool {
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
    func findAvailablePetname(petname: PetnamePart) async throws -> PetnamePart {
        var name = petname
        var count = 0
        
        while await hasEntryForPetname(petname: name) {
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
    
    func getPetname(petname: PetnamePart) async throws -> Did? {
        return try? await self.sphere.getPetname(petname: petname)
    }

    nonisolated func getPetnamePublisher(
        petname: PetnamePart
    ) -> AnyPublisher<Did?, Error> {
        Future.detached(priority: .utility) {
            try await self.getPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func setPetname(did: Did, petname: PetnamePart) async throws {
        try await sphere.setPetname(did: did, petname: petname)
    }

    nonisolated func setPetnamePublisher(
        did: Did,
        petname: PetnamePart
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
          try await self.setPetname(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func unsetPetname(petname: PetnamePart) async throws {
        try await sphere.setPetname(did: nil, petname: petname)
    }

    nonisolated func unsetPetnamePublisher(
        petname: PetnamePart
    ) -> AnyPublisher<Void, Error> {
        Future.detached(priority: .utility) {
          try await self.unsetPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func listPetnames() async throws -> [PetnamePart] {
        try await sphere.listPetnames()
    }

    func listPetnamesPublisher() -> AnyPublisher<[PetnamePart], Error> {
        Future.detached(priority: .utility) {
          try await self.listPetnames()
        }
        .eraseToAnyPublisher()
    }

    func getPetnameChanges(since cid: Cid) async throws -> [PetnamePart] {
        return try await sphere.getPetnameChanges(since: cid)
    }
      
    func getPetnameChangesPublisher(since cid: Cid) -> AnyPublisher<[PetnamePart], Error> {
        Future.detached(priority: .utility) {
            try await self.getPetnameChanges(since: cid)
        }
        .eraseToAnyPublisher()
    }
    
    func isFollowing(did: Did) async -> Bool {
        do {
            return try await listEntries(refetch: false)
                .contains(where: { f in
                    f.did == did
                })
        } catch {
            logger.warning("Failed to check following status.")
            return false
        }
    }
}

/// AddressBookService wraps an AddressBook around NoosphereService and keeps
/// the database in-sync with any follow / unfollows.
actor AddressBookService {
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: AddressBook<NoosphereService>
    
    private var pendingFollows: [PetnamePart] = []
    
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
    /// This is cached after the first use unless requested using refetch.
    /// If an error occurs producing the entries the resulting list will be empty.
    func listEntries(
        refetch: Bool = false
    ) async throws -> [AddressBookEntry] {
        return try await self.addressBook.listEntries(refetch: refetch)
    }

    /// Get the full list of entries in the address book.
    /// This is cached after the first use unless requested using refetch.
    /// If an error occurs producing the entries the resulting list will be empty.
    nonisolated func listEntriesPublisher(
        refetch: Bool = false
    ) -> AnyPublisher<[AddressBookEntry], Error> {
        Future.detached {
            try await self.addressBook.listEntries(refetch: refetch)
        }
        .eraseToAnyPublisher()
    }
    
    /// Associates the passed DID with the passed petname within the sphere, clears the cache,
    /// clears the cache, saves the changes and updates the database.
    func followUser(
        did: Did,
        petname: PetnamePart,
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
        try database.writeSphereSyncInfo(
            sphereIdentity: ourIdentity,
            version: version
        )
        await self.addressBook.invalidateCache()
    }
    
    func isPendingResolution(petname: PetnamePart) -> Bool {
        self.pendingFollows.contains(petname)
    }
    
    func waitForPetnameResolution(
        petname: PetnamePart
    ) async throws -> Cid? {
        let maxAttempts = 10 // 1+2+4+8+16+32+32+32+32+32 = 191 seconds
        
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
            
            return try await self.noosphere.resolvePetname(petname: petname.toPetname())
        }
        
        self.pendingFollows.removeAll { f in f == petname }
        
        return cid
    }
    
    nonisolated func waitForPetnameResolutionPublisher(
        petname: PetnamePart
    ) -> AnyPublisher<Cid?, Error> {
        Future.detached {
            try await self.waitForPetnameResolution(
                petname: petname
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Associates the passed DID with the passed petname within the sphere,
    /// clears the cache, saves the changes and updates the database.
    nonisolated func followUserPublisher(
        did: Did,
        petname: PetnamePart,
        preventOverwrite: Bool = false
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.followUser(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Disassociates the passed Petname from any DID within the sphere,
    /// clears the cache, saves the changes and updates the database.
    func unfollowUser(petname: PetnamePart) async throws {
        let ourIdentity = try await noosphere.identity()
        try await self.addressBook.unsetPetname(petname: petname)
        let version = try await self.noosphere.save()
        try database.writeSphereSyncInfo(
            sphereIdentity: ourIdentity,
            version: version
        )
        await self.addressBook.invalidateCache()
    }
    
    /// Disassociates the passed DID from any petname(s) in the address book,
    /// clears the cache, saves the changes and updates the database.
    /// Requires listing the contents of the address book.
    func unfollowUser(did: Did) async throws {
        let entries = try await listEntries()
        
        for entry in entries where entry.did == did {
            try await unfollowUser(petname: entry.nickname)
        }
    }
    
    /// Unassociates the passed petname with any DID in the sphere,
    /// saves the changes and updates the database.
    nonisolated func unfollowUserPublisher(
        petname: PetnamePart
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.unfollowUser(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Unassociates the passed DID with from any petname within the sphere,
    /// saves the changes and updates the database.
    nonisolated func unfollowUserPublisher(
        did: Did
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.unfollowUser(did: did)
        }
        .eraseToAnyPublisher()
    }

    func getPetname(petname: PetnamePart) async throws -> Did? {
        try await self.noosphere.getPetname(petname: petname)
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    func hasEntryForPetname(petname: PetnamePart) async -> Bool {
        await self.addressBook.hasEntryForPetname(petname: petname)
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    nonisolated func hasEntryForPetnamePublisher(petname: PetnamePart) -> AnyPublisher<Bool, Never> {
        Future.detached {
            await self.addressBook.hasEntryForPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Iteratively add a numerical suffix to petnames until we find an available alias.
    /// This can fail if `maxAttemptsToIncrementPetName` iterations occur without
    /// finding a candidate.
    func findAvailablePetname(petname: PetnamePart) async throws -> PetnamePart {
        try await self.addressBook.findAvailablePetname(petname: petname)
    }
    
    /// Iteratively add a numerical suffix to petnames until we find an available alias.
    /// This can fail if `maxAttemptsToIncrementPetName` iterations occur without
    /// finding a candidate.
    nonisolated func findAvailablePetnamePublisher(
        petname: PetnamePart
    ) -> AnyPublisher<PetnamePart, Error> {
        Future.detached {
            try await self.addressBook.findAvailablePetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Is this user in the AddressBook?
    func isFollowingUser(did: Did) async -> Bool {
        await self.addressBook.isFollowing(did: did)
    }
    
    /// Is this user in the AddressBook?
    nonisolated func isFollowingUserPublisher(did: Did) -> AnyPublisher<Bool, Error> {
        Future.detached {
            try await self.addressBook.isFollowingUser(did: did)
        }
        .eraseToAnyPublisher()
    }
}
