//
//  FollowUserForm.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 12/4/2023.
//

import ObservableStore

enum FollowUserFormAction: Equatable {
    case didField(FormFieldAction<String>)
    case petnameField(FormFieldAction<String>)
}

struct FollowUserFormModel: ModelProtocol {
    typealias Action = FollowUserFormAction
    typealias Environment = ()
    
    var did: FormField<String, Did> = FormField(value: "", validate: Self.validateDid)
    var petname: FormField<String, Petname> = FormField(value: "", validate: Self.validatePetname)
    
    static func validateDid(key: String) -> Did? {
        Did(key)
    }

    static func validatePetname(petname: String) -> Petname? {
        Petname(petname)
    }
    
    static func update(state: Self, action: Action, environment: Environment) -> Update<Self> {
        switch action {
        case .didField(let action):
            return DidFieldCursor.update(state: state, action: action, environment: FormFieldEnvironment())
        case .petnameField(let action):
            return PetnameFieldCursor.update(state: state, action: action, environment: FormFieldEnvironment())
        }
    }
}

struct PetnameFieldCursor: CursorProtocol {
    typealias Model = FollowUserFormModel
    typealias ViewModel = FormField<String, Petname>

    static func get(state: Model) -> ViewModel {
        state.petname
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.petname = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        FollowUserFormAction.petnameField(action)
    }
}

struct DidFieldCursor: CursorProtocol {
    typealias Model = FollowUserFormModel
    typealias ViewModel = FormField<String, Did>

    static func get(state: Model) -> ViewModel {
        state.did
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.did = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        FollowUserFormAction.didField(action)
    }
}
