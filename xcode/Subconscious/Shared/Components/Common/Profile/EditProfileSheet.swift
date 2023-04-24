//
//  EditProfileSheet.swift
//  Subconscious
//
//  Created by Ben Follington on 24/4/2023.
//

import os
import ObservableStore
import SwiftUI
import Combine

enum EditProfileSheetAction: Equatable {
    case populate(UserProfileEntry?)
    case nicknameField(FormFieldAction<String>)
    case bioField(FormFieldAction<String>)
    case pfpUrlField(FormFieldAction<String>)
}

private struct NicknameFieldCursor: CursorProtocol {
    typealias Model = EditProfileSheetModel
    typealias ViewModel = FormField<String, String>

    static func get(state: Model) -> ViewModel {
        state.nicknameField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.nicknameField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .nicknameField(action)
    }
}

private struct BioFieldCursor: CursorProtocol {
    typealias Model = EditProfileSheetModel
    typealias ViewModel = FormField<String, String>

    static func get(state: Model) -> ViewModel {
        state.bioField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.bioField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .bioField(action)
    }
}

private struct PfpUrlFieldCursor: CursorProtocol {
    typealias Model = EditProfileSheetModel
    typealias ViewModel = FormField<String, URL>

    static func get(state: Model) -> ViewModel {
        state.pfpUrlField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.pfpUrlField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .pfpUrlField(action)
    }
}

struct EditProfileSheetEnvironment { }

struct EditProfileSheetModel: ModelProtocol {
    typealias Action = EditProfileSheetAction
    typealias Environment = EditProfileSheetEnvironment
    
    var nicknameField: FormField<String, String> = FormField(value: "", validate: { x in x })
    var bioField: FormField<String, String> = FormField(value: "", validate: { x in x })
    var pfpUrlField: FormField<String, URL> = FormField(value: "", validate: { x in URL(string: x) })
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "EditProfileSheet"
    )
    
    static func update(state: Self, action: Action, environment: Environment) -> Update<Self> {
        switch action {
        case .populate(let user):
            return update(
                state: state,
                actions: [
                    .nicknameField(.setValue(input: user?.preferredName ?? "")),
                    .bioField(.setValue(input: user?.bio ?? "")),
                    .pfpUrlField(.setValue(input: user?.profilePictureUrl ?? ""))
                ],
                environment: environment
            )
            
        case .nicknameField(let action):
            return NicknameFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
            
        case .bioField(let action):
            return BioFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
            
        case .pfpUrlField(let action):
            return PfpUrlFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        }
    }
}

struct EditProfileSheet: View {
    var state: EditProfileSheetModel
    var send: (EditProfileSheetAction) -> Void
    var user: UserProfile
    var onEditProfile: () -> Void
    
    var body: some View {
        Text("test")
    }
}

