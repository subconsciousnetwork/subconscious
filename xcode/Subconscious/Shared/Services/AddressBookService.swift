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

class AddressBookService {
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
    func listEntries(refetch: Bool = false) -> AnyPublisher<[AddressBookEntry], Never> {
        if let entries = addressBook {
            if !refetch {
                return Just(entries).eraseToAnyPublisher()
            }
        }
        
        return self.listPetnamesAsync()
            .flatMap { follows in
                return Publishers.MergeMany(follows.map { f in
                    return self.getPetnameAsync(petname: f)
                        .map { did -> AddressBookEntry? in
                            guard let did = did else { return nil }
                            // TODO: hardcoded pfp
                            return AddressBookEntry(pfp: AppTheme.brandMark, petname: f, did: did)
                        }
                        .compactMap { value in value }
                })
                .collect()
                .eraseToAnyPublisher()
            }
            .catch { err in
                Just([])
            }
            .map { entries in
                // Here be dragons (mutation) to cache the result
                self.addressBook = entries
                return entries
            }
            .eraseToAnyPublisher()
    }
    
    func followUser(did: Did, petname: Petname) throws {
        if try self.noosphere.identity() == did.id {
            throw AddressBookError.cannotFollowYourself
        }
        
        try setPetname(did: did, petname: petname)
        let version = try self.noosphere.save()
        try database.writeMetadatadata(key: .sphereVersion, value: version)
    }
    
    /// Associates the passed DID with the passed petname within the sphere, saves the changes and updates the database.
    func followUserAsync(did: Did, petname: Petname) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .default) {
            return try self.followUser(did: did, petname: petname)
        }
    }
    
    func unfollowUser(petname: Petname) throws {
        try unsetPetname(petname: petname)
        let version = try self.noosphere.save()
        try database.writeMetadatadata(key: .sphereVersion, value: version)
    }
    
    /// Unassociates the passed DID with the passed petname within the sphere, saves the changes and updates the database.
    func unfollowUserAsync(petname: Petname) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .default) {
            return try self.unfollowUser(petname: petname)
        }
    }
    
    func getPetname(petname: Petname) throws -> Did? {
        return try Did(noosphere.getPetname(petname: petname.verbatim))
    }

    func getPetnameAsync(petname: Petname) -> AnyPublisher<Did?, Error> {
        CombineUtilities.async(qos: .utility) {
          return try self.getPetname(petname: petname)
        }
    }

    func setPetname(did: Did, petname: Petname) throws {
        try noosphere.setPetname(did: did.did, petname: petname.verbatim)
    }

    func setPetnameAsync(did: Did, petname: Petname) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
          try self.setPetname(did: did, petname: petname)
        }
    }

    func unsetPetname(petname: Petname) throws {
        try noosphere.unsetPetname(petname: petname.verbatim)
    }

    func unsetPetnameAsync(petname: Petname) -> AnyPublisher<Void, Error> {
        CombineUtilities.async(qos: .utility) {
          try self.unsetPetname(petname: petname)
        }
    }

    func listPetnames() throws -> [Petname] {
        return try noosphere.listPetnames()
            .map { name in Petname(name) }
            .compactMap { $0 }
    }

    func listPetnamesAsync() -> AnyPublisher<[Petname], Error> {
        CombineUtilities.async(qos: .utility) {
          return try self.listPetnames()
        }
    }

    func getPetnameChanges(sinceCid: String) throws -> [String] {
        return try noosphere.getPetnameChanges(sinceCid: sinceCid)
    }
      
    func getPetnameChangesAsync(sinceCid: String) -> AnyPublisher<[String], Error> {
        CombineUtilities.async(qos: .utility) {
            return try self.getPetnameChanges(sinceCid: sinceCid)
        }
    }
}
