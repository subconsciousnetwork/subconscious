//
//  AddressBookService.swift
//  Subconscious
//
//  Created by Ben Follington on 14/3/2023.
//

import os
import Foundation
import Combine
// temp
import SwiftUI

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
            return String(localized: "You cannot follow yourself.", comment: "Address Book error description")
        case .alreadyFollowing:
            return String(localized: "You are already following {}.", comment: "Address Book error description")
        case .failedToIncrementPetname:
            return String(localized: "Failed to increment a petname's suffix.", comment: "Address Book error description")
        case .exhaustedUniquePetnameRange:
            return String(localized: "Failed to find an available petname.", comment: "Address Book error description")
        case .invalidAttemptToOverwitePetname:
            return String(localized: "This petname is already in use.", comment: "Address Book error description")
        case .other(let msg):
            return String(localized: "An unknown error occurred: \(msg)", comment: "Unknown Address Book error description")
        }
    }
}

actor AddressBookService {
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: [AddressBookEntry]?
    
    private static let MAX_ATTEMPTS_TO_INCREMENT_PETNAME = 99
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddressBookService"
    )
    
    init(noosphere: NoosphereService, database: DatabaseService) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = nil
    }
    
    private func invalidateCache() {
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
        let petnames = try await noosphere.listPetnames()
        for petname in petnames {
            let did = try await Did(noosphere.getPetname(petname: petname))
                .unwrap()
            addressBook.append(
                AddressBookEntry(
                    pfp: AppTheme.brandMark,
                    petname: petname,
                    did: did
                )
            )
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
        Future.detatched {
            try await self.listEntries(refetch: refetch)
        }
        .eraseToAnyPublisher()
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    func hasEntryForPetname(petname: Petname) async -> Bool {
        do {
            let _  = try await self.noosphere.getPetname(petname: petname)
            return true
        } catch {
            Self.logger.error("An error occurred checking for \(petname.markup), returning false. Reason: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Is there a user with this petname in the AddressBook?
    /// This method is designed not to throw for a quick check.
    nonisolated func hasEntryForPetnamePublisher(petname: Petname) -> AnyPublisher<Bool, Never> {
        Future.detatched {
            return await self.hasEntryForPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Is this user in the AddressBook?
    func isFollowingUser(did: Did) async throws -> Bool {
        let entries = try await listEntries()
        
        return entries.contains(where: { entry in
            entry.did == did
        })
    }
    
    /// Is this user in the AddressBook?
    nonisolated func isFollowingUserPublisher(did: Did) -> AnyPublisher<Bool, Error> {
        Future.detatched {
            return try await self.isFollowingUser(did: did)
        }
        .eraseToAnyPublisher()
    }
    
    /// Iteratively add a numerical suffix to petnames until we find an available alias.
    /// This can fail if `MAX_ATTEMPTS_TO_INCREMENT_PETNAME` iterations occur without
    /// finding a candidate.
    func findAvailablePetname(petname: Petname) async throws -> Petname {
        var name = petname
        var count = 0
        
        while await hasEntryForPetname(petname: name) {
            guard let next = name.increment() else {
                throw AddressBookError.exhaustedUniquePetnameRange
            }
           
            name = next
            count += 1
            
            // Escape hatch, no infinite loops plz
            if count > Self.MAX_ATTEMPTS_TO_INCREMENT_PETNAME {
                throw AddressBookError.exhaustedUniquePetnameRange
            }
        }
        
        return name
    }
    
    /// Iteratively add a numerical suffix to petnames until we find an available alias.
    /// This can fail if `MAX_ATTEMPTS_TO_INCREMENT_PETNAME` iterations occur without
    /// finding a candidate.
    nonisolated func findAvailablePetnamePublisher(petname: Petname) -> AnyPublisher<Petname, Error> {
        Future.detatched {
            return try await self.findAvailablePetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Associates the passed DID with the passed petname within the sphere, clears the cache,
    /// saves the changes and updates the database.
    func followUser(
        did: Did,
        petname: Petname,
        preventOverwrite: Bool = false
    ) async throws {
        if try await noosphere.identity() == did.id {
            throw AddressBookError.cannotFollowYourself
        }
        
        let hasEntry = await hasEntryForPetname(petname: petname)
        if preventOverwrite && hasEntry {
            throw AddressBookError.invalidAttemptToOverwitePetname
        }
        
        try await noosphere.setPetname(did: did.did, petname: petname)
        let version = try await noosphere.save()
        try database.writeMetadatadata(key: .sphereVersion, value: version)
        invalidateCache()
    }
    
    /// Associates the passed DID with the passed petname within the sphere,
    /// saves the changes and updates the database.
    nonisolated func followUserPublisher(
        did: Did,
        petname: Petname,
        preventOverwrite: Bool = false
    ) -> AnyPublisher<Void, Error> {
        Future.detatched {
            try await self.followUser(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Disassociates the passed Petname from any DID within the sphere, clears the cache, saves the changes and updates the database.
    func unfollowUser(petname: Petname) async throws {
        try await unsetPetname(petname: petname)
        let version = try await noosphere.save()
        try database.writeMetadatadata(key: .sphereVersion, value: version)
        invalidateCache()
    }
    
    /// Disassociates the passed DID from any petname(s) in the address book, clears the cache, saves the changes and updates the database.
    /// Requires listing the contents of the address book.
    func unfollowUser(did: Did) async throws {
        let entries = try await listEntries()
        
        for entry in entries {
            if entry.did == did {
                try await unfollowUser(petname: entry.petname)
            }
        }
    }
    
    /// Unassociates the passed petname with any DID in the sphere,
    /// saves the changes and updates the database.
    nonisolated func unfollowUserPublisher(
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detatched {
            try await self.unfollowUser(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Unassociates the passed DID with from any petname within the sphere,
    /// saves the changes and updates the database.
    nonisolated func unfollowUserPublisher(
        did: Did
    ) -> AnyPublisher<Void, Error> {
        Future.detatched {
            try await self.unfollowUser(did: did)
        }
        .eraseToAnyPublisher()
    }
    
    nonisolated func getPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Did?, Never> {
        Future.detatched(priority: .utility) {
            try? await Did(self.noosphere.getPetname(petname: petname))
        }
        .eraseToAnyPublisher()
    }

    func setPetname(did: Did, petname: Petname) async throws {
        try await noosphere.setPetname(did: did.did, petname: petname)
    }

    nonisolated func setPetnamePublisher(
        did: Did,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detatched {
          try await self.setPetname(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }

    func unsetPetname(petname: Petname) async throws {
        try await noosphere.setPetname(did: nil, petname: petname)
    }

    nonisolated func unsetPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detatched(priority: .utility) {
          try await self.unsetPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
}
