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
    typealias ViewModel = FormField<String, Petname>

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

typealias EditProfileSheetEnvironment = Void

struct EditProfileSheetModel: ModelProtocol {
    typealias Action = EditProfileSheetAction
    typealias Environment = EditProfileSheetEnvironment
    
    var nicknameField: FormField<String, Petname> = FormField(
        value: "",
        validate: { value in
            Petname(value)
        }
    )
    var bioField: FormField<String, String> = FormField(
        value: "",
        validate: { value in
            value.count >= 280 ? nil : value
        }
    )
    var pfpUrlField: FormField<String, URL> = FormField(
        value: "",
        validate: { value in
            URL(string: value)
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
                    .pfpUrlField(.reset),
                    .nicknameField(.setValue(input: user?.nickname ?? "")),
                    .bioField(.setValue(input: user?.bio ?? "")),
                    .pfpUrlField(.setValue(input: user?.profilePictureUrl ?? "")),
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
    var statistics: UserProfileStatistics?
    var failEditProfileMessage: String?
    var onEditProfile: () -> Void
    var onCancel: () -> Void
    var onDismissError: () -> Void
    
    func makePreview(nickname: Petname) -> UserProfile {
        let pfp: ProfilePicVariant = Func.run {
            let did = user.did
            if let url = state.pfpUrlField.validated {
                return ProfilePicVariant.url(url)
            }
            
            return ProfilePicVariant.none(did)
        }
        
        return UserProfile(
            did: user.did,
            nickname: nickname,
            address: user.address,
            pfp: pfp,
            bio: state.bioField.validated ?? "",
            category: .you
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "at")
                            .foregroundColor(.accentColor)
                        ValidatedTextField(
                            placeholder: "nickname",
                            text: Binding(
                                get: { state.nicknameField.value },
                                send: send,
                                tag: { v in .nicknameField(.setValue(input: v))}
                            ),
                            onFocusChanged: { focused in
                                send(.nicknameField(.focusChange(focused: focused)))
                            },
                            caption: "How you would like to be known",
                            hasError: state.nicknameField.hasError
                        )
                        .formField()
                        .lineLimit(1)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    }
                    
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "photo")
                            .foregroundColor(.accentColor)
                        ValidatedTextField(
                            placeholder: "http://example.org/pfp.jpg",
                            text: Binding(
                                get: { state.pfpUrlField.value },
                                send: send,
                                tag: { v in .pfpUrlField(.setValue(input: v))}
                            ),
                            onFocusChanged: { focused in
                                send(.pfpUrlField(.focusChange(focused: focused)))
                            },
                            caption: "The image shown on your profile",
                            hasError:
                                !state.pfpUrlField.isValid &&
                                state.pfpUrlField.value.count > 0
                        )
                        .formField()
                        .lineLimit(1)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "text.quote")
                            .foregroundColor(.accentColor)
                        ValidatedTextField(
                            placeholder: "bio",
                            text: Binding(
                                get: { state.bioField.value },
                                send: send,
                                tag: { v in .bioField(.setValue(input: v))}
                            ),
                            onFocusChanged: { focused in
                                send(.bioField(.focusChange(focused: focused)))
                            },
                            caption:
                                "A short description of yourself (\(state.bioField.value.count)/280)",
                            hasError:
                                !state.bioField.isValid &&
                                state.bioField.value.count > 0,
                            axis: .vertical
                        )
                        .formField()
                        .lineLimit(3)
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
                            isFollowingUser: false,
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onEditProfile()
                    }
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

