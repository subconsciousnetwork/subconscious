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
import Combine

struct AddressBookEntry: Equatable {
    var pfp: Image
    var petname: Petname
    var did: Did
}

struct AddressBookEnvironment {
    var noosphere: SphereIdentityProtocol
    var data: DataService
}

// Used for SwiftUI Previews, also useful for testing
class PlaceholderSphereIdentityProvider: SphereIdentityProtocol {
    func identity() throws -> String {
        "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
    }
}

enum AddressBookAction: Hashable {
    case present(_ isPresented: Bool)
    
    case requestFollow(did: Did, petname: Petname)
    case failFollow(error: String)
    case succeedFollow(did: Did, petname: Petname)
    
    case requestUnfollow(petname: Petname)
    case failUnfollow(error: String)
    case succeedUnfollow(petname: Petname)
}

struct AddressBookModel: ModelProtocol {
    var isPresented = false
    var did: Did? = nil
    var follows: [AddressBookEntry] = []
    
    var failFollowErrorMessage: String? = nil
    var failUnfollowErrorMessage: String? = nil

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
            
            // TODO: we need to ls the address book contents and hydrate the model
            
            return Update(state: model)
            
        case .requestFollow(did: let did, petname: let petname):
            let fx: Fx<AddressBookAction> = environment.data
                .setPetnameAsync(did: did, petname: petname)
                .map({ _ in
                    AddressBookAction.succeedFollow(did: did, petname: petname)
                })
                .catch({ error in
                    Just(
                        AddressBookAction.failFollow(error: error.localizedDescription)
                    )
                })
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedFollow(did: let did, petname: let petname):
            // Guard against duplicates
            guard !state.follows.contains(where: { entry in entry.did == did }) else {
                return Update(state: state)
            }
            
            let entry = AddressBookEntry(pfp: Image("sub_logo_dark"), petname: petname, did: did)
            
            var model = state
            model.follows.append(entry)
            return Update(state: model)
            
        case .failFollow(error: let error):
            var model = state
            model.failFollowErrorMessage = error
            return Update(state: model)
            
        case .requestUnfollow(petname: let petname):
            let fx: Fx<AddressBookAction> = environment.data
                .unsetPetnameAsync(petname: petname)
                .map({ _ in
                    AddressBookAction.succeedUnfollow(petname: petname)
                })
                .catch({ error in
                    Just(
                        AddressBookAction.failUnfollow(error: error.localizedDescription)
                    )
                })
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedUnfollow(let petname):
            var model = state
            model.follows.removeAll { f in
                f.petname == petname
            }
            return Update(state: model)
            
        case .failUnfollow(error: let error):
            var model = state
            model.failUnfollowErrorMessage = error
            return Update(state: model)
        }
    }
}
