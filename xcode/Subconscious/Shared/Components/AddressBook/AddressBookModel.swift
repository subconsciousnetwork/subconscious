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

typealias Validator<I, O> = (I) -> O?

struct FormField<I : Equatable, O>: Equatable {
    static func == (lhs: FormField<I, O>, rhs: FormField<I, O>) -> Bool {
        return lhs.value == rhs.value && lhs.touched == rhs.touched && lhs.isValid == rhs.isValid
    }
    
    var value: I
    var validate: Validator<I, O>
    var touched: Bool = false
    
    func update(input: I) -> Self {
        Self(value: input, validate: validate, touched: touched)
    }
    
    /// Only marked as touched when field _loses_ focus
    func touch(focused: Bool = false) -> Self {
        Self(value: value, validate: validate, touched: focused ? touched : true)
    }
    
    var validated: O? {
        get {
            validate(value)
        }
    }
    var isValid: Bool {
        get {
            validated != nil
        }
    }
    var hasError: Bool {
        get {
            !isValid && touched
        }
    }
}

struct FollowUserForm: Equatable {
    var did: FormField<String, Did> = FormField(value: "", validate: Self.validateDid)
    var petname: FormField<String, Petname> = FormField(value: "", validate: Self.validatePetname)
    
    static func validateDid(key: String) -> Did? {
        Did(key)
    }

    static func validatePetname(petname: String) -> Petname? {
        Petname(petname)
    }
}

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
    
    case requestFollow
    case failFollow(error: String)
    case succeedFollow(did: Did, petname: Petname)
    
    case requestUnfollow(petname: Petname)
    case failUnfollow(error: String)
    case succeedUnfollow(petname: Petname)
    
    // Form actions, could be a sub-enum
    case presentFollowUserForm(_ isPresented: Bool)
    case setDidField(input: String)
    case touchDidField(focused: Bool)
    case setPetnameField(input: String)
    case touchPetnameField(focused: Bool)
}

struct AddressBookModel: ModelProtocol {
    var isPresented = false
    var did: Did? = nil
    var follows: [AddressBookEntry] = []
    
    var followUserFormIsPresented = false
    var followUserForm = FollowUserForm()
    
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
            
        case .presentFollowUserForm(let isPresented):
            var model = state
            
            model.followUserFormIsPresented = isPresented
            if isPresented {
                // Reset form when opened
                model.followUserForm = FollowUserForm()
            }
            
            return Update(state: model)
            
        case .touchDidField(let focused):
            var model = state
            model.followUserForm.did = state.followUserForm.did.touch(focused: focused)
            return Update(state: model)
            
        case .setDidField(input: let input):
            var model = state
            model.followUserForm.did = model.followUserForm.did.update(input: input)
            return Update(state: model)
            
        case .touchPetnameField(let focused):
            var model = state
            model.followUserForm.petname = state.followUserForm.petname.touch(focused: focused)
            return Update(state: model)
            
        case .setPetnameField(input: let input):
            var model = state
            model.followUserForm.petname = model.followUserForm.petname.update(input: input)
            return Update(state: model)
            
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
            
        case .requestFollow:
            var model = state
            // Show errors on any untouched fields, hints at why you cannot submit
            model.followUserForm.did = model.followUserForm.did.touch()
            model.followUserForm.petname = model.followUserForm.petname.touch()
            
            guard let did = state.followUserForm.did.validated else {
                return Update(state: model)
            }
            guard let petname = state.followUserForm.petname.validated else {
                return Update(state: model)
            }
            // Guard against duplicates
            guard !state.follows.contains(where: { entry in entry.did == did }) else {
                return Update(state: model)
            }
            
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
            
            return Update(state: model, fx: fx)
            
        case .succeedFollow(did: let did, petname: let petname):
            let entry = AddressBookEntry(pfp: Image("sub_logo_dark"), petname: petname, did: did)
            
            var model = state
            model.followUserFormIsPresented = false
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
