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
        case .populate(let user):
            return update(
                state: state,
                actions: [
                    .nicknameField(.reset),
                    .bioField(.reset),
                    .nicknameField(.setValue(input: user?.nickname ?? "")),
                    .bioField(.setValue(input: user?.bio ?? "")),
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
        }
    }
}


struct EditProfileSheet: View {
    var state: EditProfileSheetModel
    var send: (EditProfileSheetAction) -> Void
    var user: UserProfile
    var statistics: UserProfileStatistics?
    var failEditProfileMessage: String?
    var onEditProfile: () -> Void
    var onCancel: () -> Void
    var onDismissError: () -> Void
    
    var formIsValid: Bool {
        state.bioField.isValid && state.nicknameField.isValid
    }
    
    func makePreview(nickname: Petname.Name) -> UserProfile {
        let pfp: ProfilePicVariant = ProfilePicVariant.generated(user.did)
        
        return UserProfile(
            did: user.did,
            nickname: nickname,
            address: user.address,
            pfp: pfp,
            bio: UserProfileBio(state.bioField.validated?.text ?? ""),
            category: .ourself,
            resolutionStatus: .resolved(Cid("fake-for-preview")),
            ourFollowStatus: .notFollowing
        )
    }
    
    var bioCaption: String {
        "A short description of yourself (\(state.bioField.value.count)/280)"
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
                            field: state.nicknameField,
                            send: Address.forward(
                                send: send,
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
                            field: state.bioField,
                            send: Address.forward(
                                send: send,
                                tag: EditProfileSheetAction.bioField
                            ),
                            caption: bioCaption,
                            axis: .vertical
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    }
                }
                
                if let nickname = state.nicknameField.validated {
                    let preview = makePreview(nickname: nickname)
                    
                    Section("Preview") {
                        UserProfileHeaderView(
                            user: preview,
                            statistics: statistics,
                            hideActionButton: true
                        )
                    }
                }
            }
            .alert(
                isPresented: Binding(
                    get: { failEditProfileMessage != nil },
                    set: { _ in onDismissError() }
                )
            ) {
                Alert(
                    title: Text("Failed to Save Profile"),
                    message: Text(failEditProfileMessage ?? "An unknown error ocurred")
                )
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onEditProfile()
                    }
                    .disabled(!formIsValid)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                }
            }
        }
    }
}

