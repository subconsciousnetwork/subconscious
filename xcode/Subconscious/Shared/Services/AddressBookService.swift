//
//  AddressBookService.swift
//  Subconscious
//
//  Created by Ben Follington on 14/3/2023.
//

import Foundation
import Combine
// temp
import SwiftUI

enum AddressBookError: Error {
    case cannotFollowYourself
    case alreadyFollowing
    case other(String)
}

extension AddressBookError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cannotFollowYourself:
            return String(localized: "You cannot follow yourself.", comment: "Address Book error description")
        case .alreadyFollowing:
            return String(localized: "You are already following {}.", comment: "Address Book error description")
        case .other(let msg):
            return String(localized: "An unknown error occurred: \(msg)", comment: "Unknown Address Book error description")
        }
    }
}

actor AddressBookService {
    private(set) var noosphere: NoosphereService
    private(set) var database: DatabaseService
    private var addressBook: [AddressBookEntry]?
    
    init(noosphere: NoosphereService, database: DatabaseService) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = nil
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
    
    func followUser(did: Did, petname: Petname) async throws {
        if try await noosphere.identity() == did.id {
            throw AddressBookError.cannotFollowYourself
        }
        
        try await noosphere.setPetname(did: did.did, petname: petname)
        let version = try await noosphere.save()
        try database.writeMetadatadata(key: .sphereVersion, value: version)
    }
    
    /// Associates the passed DID with the passed petname within the sphere,
    /// saves the changes and updates the database.
    nonisolated func followUserPublisher(
        did: Did,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detatched {
            try await self.followUser(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    func unfollowUser(petname: Petname) async throws {
        try await unsetPetname(petname: petname)
        let version = try await noosphere.save()
        try database.writeMetadatadata(key: .sphereVersion, value: version)
    }
    
    /// Unassociates the passed DID with the passed petname within the sphere,
    /// saves the changes and updates the database.
    nonisolated func unfollowUserPublisher(
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detatched {
            try await self.unfollowUser(petname: petname)
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
