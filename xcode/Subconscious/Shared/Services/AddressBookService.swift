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

class AddressBookService {
    private(set) var noosphere: NoosphereService
    private var addressBook: [AddressBookEntry]?
    
    init(noosphere: NoosphereService) {
        self.noosphere = noosphere
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
                            // TODO: hardcoded dog-pfp
                            return AddressBookEntry(pfp: Image("dog-pfp"), petname: f, did: did)
                        }
                        .compactMap { $0 }
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
