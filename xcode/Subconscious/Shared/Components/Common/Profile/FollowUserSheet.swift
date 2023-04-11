//
//  FollowUserSheet.swift
//  Subconscious
//
//  Created by Ben Follington on 11/4/2023.
//

import ObservableStore
import SwiftUI

enum FollowUserSheetAction: Equatable {
    case populate(UserProfile)
    case followUserForm(FollowUserFormAction)
}

struct FollowUserSheetModel: ModelProtocol {
    typealias Action = FollowUserSheetAction
    typealias Environment = ()
    
    var followUserForm: FollowUserFormModel = FollowUserFormModel()
    
    static func update(state: Self, action: Action, environment: Environment) -> Update<Self> {
        switch action {
        case .populate(let user):
            return update(
                state: state,
                actions: [
                    .followUserForm(.didField(.setValue(input: user.did.did))),
                    .followUserForm(.petnameField(.setValue(input: user.petname.verbatim)))
                ],
                environment: environment
            )
        case .followUserForm(let action):
            return FollowUserSheetFormCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        }
    }
}

struct FollowUserSheetCursor: CursorProtocol {
    typealias Model = UserProfileDetailModel
    typealias ViewModel = FollowUserSheetModel
    
    static func get(state: Model) -> ViewModel {
        state.followUserSheet
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.followUserSheet = inner
        return model
    }
    
    static func tag(_ action: FollowUserSheetAction) -> UserProfileDetailAction {
        .followUserSheet(action)
    }
}

struct FollowUserSheetFormCursor: CursorProtocol {
    typealias Model = FollowUserSheetModel
    typealias ViewModel = FollowUserFormModel
    
    static func get(state: FollowUserSheetModel) -> FollowUserFormModel {
        state.followUserForm
    }
    
    static func set(state: FollowUserSheetModel, inner: FollowUserFormModel) -> FollowUserSheetModel {
        var model = state
        model.followUserForm = inner
        return model
    }
    
    static func tag(_ action: FollowUserFormAction) -> FollowUserSheetAction {
        .followUserForm(action)
    }
}

struct FollowUserSheet: View {
    var state: FollowUserSheetModel
    var send: (FollowUserSheetAction) -> Void
    var user: UserProfile
    
    var onAttemptFollow: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: AppTheme.unit2) {
            ProfilePic(image: Image(user.pfp))
            
            Text(user.did.did)
                .font(.caption.monospaced())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            ValidatedTextField(
                placeholder: "@petname",
                text: Binding(
                    get: { state.followUserForm.petname.value },
                    send: send,
                    tag: { input in
                        .followUserForm(.petnameField(.setValue(input: input)))
                    }
                ),
                caption: "You already follow @petname"
            )
            .textFieldStyle(.roundedBorder)
            
            Spacer()
            
            Button(
                action: onAttemptFollow,
                label: {
                    if let petname = state.followUserForm.petname.validated {
                        Text("Follow \(petname.markup)")
                    } else {
                        Text("Invalid petname")
                    }
                }
            )
            .buttonStyle(PillButtonStyle())
            .disabled(!state.followUserForm.petname.isValid)
        }
        .padding(AppTheme.padding)
        .presentationDetents([.fraction(0.33)])
        .onAppear {
            send(.populate(user))
        }
    }
}
