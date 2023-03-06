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
class FakeSphereIdentityProvider: SphereIdentityProtocol {
    func identity() throws -> String {
        "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
    }
}

enum AddressBookAction: Hashable {
    case addFriend(did: Did, petname: Petname)
    case removeFriend(did: Did)
}

struct AddressBookModel: ModelProtocol {
    var friends: [AddressBookEntry] = []

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
        case .addFriend(did: let did, petname: let petname):
            // Guard against duplicates
            guard !state.friends.contains(where: { entry in entry.did == did }) else {
                return Update(state: state)
            }
            
            let entry = AddressBookEntry(pfp: Image("pfp-dog"), petname: petname, did: did)
            
            var model = state
            model.friends.append(entry)
            return Update(state: model)
        case .removeFriend(did: let did):
            var model = state
            
            model.friends.removeAll { entry in
                entry.did == did
            }
            return Update(state: model)
        }
    }
}
