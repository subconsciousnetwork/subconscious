//
//  AddressBookModel.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/3/2023.
//

import os
import Foundation
import SwiftUI
import ObservableStore

struct AddressBookEntry: Equatable {
    var pfp: Image
    var petname: Petname
    var did: Did
}

struct AddressBookEnvironment {
    var noosphere: SphereIdentityProtocol
}

// Used for SwiftUI Previews, also useful for testing
class PlaceholderSphereIdentityProvider: SphereIdentityProtocol {
    func identity() throws -> String {
        "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
    }
}

enum AddressBookAction: Hashable {
    case present(_ isPresented: Bool)
    case follow(did: Did, petname: Petname)
    case unfollow(did: Did)
}

struct AddressBookModel: ModelProtocol {
    var isPresented = false
    var did: Did? = nil
    var follows: [AddressBookEntry] = []

    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddressBookModel"
    )

    static func update(
        state: AddressBookModel,
        action: AddressBookAction,
        environment: AddressBookEnvironment
    ) -> Update<AddressBookModel> {
        switch action {
        case .present(let isPresented):
            var model = state
            model.isPresented = isPresented
            
            if isPresented {
                do {
                    model.did = try Did(environment.noosphere.identity())
                } catch {
                    model.did = nil
                }
            }
            
            return Update(state: model)
            
        case .follow(did: let did, petname: let petname):
            // Guard against duplicates
            guard !state.follows.contains(where: { entry in entry.did == did }) else {
                return Update(state: state)
            }
            
            let entry = AddressBookEntry(pfp: Image("sub_logo_dark"), petname: petname, did: did)
            
            var model = state
            model.follows.append(entry)
            return Update(state: model)
        case .unfollow(let did):
            var model = state
            model.follows.removeAll { f in
                f.did == did
            }
            return Update(state: model)
        }
    }
}
