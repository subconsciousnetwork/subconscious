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
    case populate(UserProfile, UserProfileStatistics?)
    case nicknameField(FormFieldAction<String>)
    case bioField(FormFieldAction<String>)
    
    case submit
    case dismiss
}

private struct NicknameFieldCursor: CursorProtocol {
    typealias Model = EditProfileSheetModel
    typealias ViewModel = FormField<String, Petname.Name>

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
    typealias ViewModel = FormField<String, UserProfileBio>

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

typealias EditProfileSheetEnvironment = Void

struct EditProfileSheetModel: ModelProtocol {
    typealias Action = EditProfileSheetAction
    typealias Environment = EditProfileSheetEnvironment
    
    var user: UserProfile? = nil
    var statistics: UserProfileStatistics? = nil
    
    var nicknameField: FormField<String, Petname.Name> = FormField(
        value: "",
        validate: { value in
            Petname.Name(value)
        }
    )
    var bioField: FormField<String, UserProfileBio> = FormField(
        value: "",
        validate: { value in
            UserProfileBio(value)
        }
    )
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "EditProfileSheet"
    )
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        
        switch action {
        case let .populate(user, statistics):
            var model = state
            model.user = user
            model.statistics = statistics
            
            return update(
                state: model,
                actions: [
                    .nicknameField(.reset),
                    .bioField(.reset),
                    .nicknameField(.setValue(input: user.nickname?.description ?? "")),
                    .bioField(.setValue(input: user.bio?.text ?? "")),
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
        // Notifications
        case .submit:
            return Update(state: state)
        case .dismiss:
            return Update(state: state)
        }
    }
}


struct EditProfileSheet: View {
    var store: ViewStore<EditProfileSheetModel>
    
    var formIsValid: Bool {
        store.state.bioField.isValid && store.state.nicknameField.isValid
    }
    
    func makePreview(nickname: Petname.Name) -> UserProfile? {
        guard let user = store.state.user else {
            return nil
        }
        let pfp: ProfilePicVariant = ProfilePicVariant.generated(user.did)
        
        return UserProfile(
            did: user.did,
            nickname: nickname,
            address: user.address,
            pfp: pfp,
            bio: UserProfileBio(store.state.bioField.validated?.text ?? ""),
            category: .ourself,
            ourFollowStatus: .notFollowing,
            aliases: []
        )
    }
    
    var bioCaption: String {
        "A short description of yourself (\(store.state.bioField.value.count)/280)"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "at")
                            .foregroundColor(.accentColor)
                        ValidatedFormField(
                            placeholder: "nickname",
                            field: store.viewStore(
                                get: \.nicknameField,
                                tag: EditProfileSheetAction.nicknameField
                            ),
                            caption: String(
                                localized: "Lowercase letters, numbers and dashes only."
                            )
                        )
                        .lineLimit(1)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "text.quote")
                            .foregroundColor(.accentColor)
                        
                        ValidatedFormField(
                            placeholder: "bio",
                            field: store.viewStore(
                                get: \.bioField,
                                tag: EditProfileSheetAction.bioField
                            ),
                            caption: bioCaption,
                            axis: .vertical
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    }
                }
                
                if let nickname = store.state.nicknameField.validated,
                   let preview = makePreview(nickname: nickname) {
                    Section("Preview") {
                        UserProfileHeaderView(
                            user: preview,
                            statistics: store.state.statistics,
                            hideActionButton: true
                        )
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.submit)
                    }
                    .disabled(!formIsValid)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        store.send(.dismiss)
                    }
                }
            }
        }
    }
}

