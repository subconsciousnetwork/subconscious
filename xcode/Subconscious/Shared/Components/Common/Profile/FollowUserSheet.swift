//
//  FollowUserSheet.swift
//  Subconscious
//
//  Created by Ben Follington on 11/4/2023.
//

import os
import ObservableStore
import SwiftUI
import Combine

enum FollowUserSheetAction: Equatable {
    case populate(UserProfile)
    case followUserForm(FollowUserFormAction)
    
    case fetchPetnameCollisionStatus(Petname.Name)
    case populatePetnameCollisionStatus(Petname.Name, Bool)
    case attemptToFindUniquePetname(Petname.Name)
    case failToFindUniquePetname(String)
}

struct FollowUserSheetEnvironment {
    var addressBook: AddressBookService
}

struct FollowUserSheetModel: ModelProtocol {
    typealias Action = FollowUserSheetAction
    typealias Environment = FollowUserSheetEnvironment
    
    var user: UserProfile? = nil
    var followUserForm: FollowUserFormModel = FollowUserFormModel()
    var isPetnamePresentInAddressBook: Bool = false
    
    var petnameFieldCaption: String? = nil
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "FollowUserSheetModel"
    )
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        
        switch action {
        case .populate(let user):
            var model = state
            model.user = user
            
            guard let bestFollowName = user.nickname ?? user.address.petname?.leaf else {
                return Update(state: model)
            }
            
            return update(
                state: model,
                actions: [
                    .followUserForm(.didField(.setValue(input: user.did.did))),
                    .followUserForm(.petnameField(.setValue(input: bestFollowName.verbatim))),
                    .fetchPetnameCollisionStatus(bestFollowName)
                ],
                environment: environment
            )
            
        case .followUserForm(let action):
            return FollowUserSheetFormCursor.update(
                state: state,
                action: action,
                environment: ()
            )
            
        case .fetchPetnameCollisionStatus(let petname):
            let fx: Fx<FollowUserSheetAction> =
                environment.addressBook.hasEntryForPetnamePublisher(petname: petname.toPetname())
                .map { collision in
                    FollowUserSheetAction.populatePetnameCollisionStatus(petname, collision)
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .populatePetnameCollisionStatus(let petname, let collision):
            var model = state
            model.isPetnamePresentInAddressBook = collision
            
            if collision {
                model.petnameFieldCaption = "You already follow a \(petname.toPetname().markup)"
                return update(
                    state: model,
                    actions: [.attemptToFindUniquePetname(petname)],
                    environment: environment
                )
            }
            
            return Update(state: model)
            
        case .attemptToFindUniquePetname(let petname):
            let fx: Fx<FollowUserSheetAction> =
                environment.addressBook.findAvailablePetnamePublisher(name: petname)
                .map { petname in
                    FollowUserSheetAction.followUserForm(
                        .petnameField(.setValue(input: petname.verbatim))
                    )
                }
                .recover { error in
                    FollowUserSheetAction.failToFindUniquePetname(error.localizedDescription)
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .failToFindUniquePetname(let error):
            // This is a no-op at the moment, if we failed to find a unique name the user
            // will be unable to submit the form anyway so adding an extra error message
            // seems redundant.
            logger.warning("Failed to find a unique petname: \(error)")
            return Update(state: state)
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
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .followUserSheet(action)
    }
}

struct FollowUserSheetFormCursor: CursorProtocol {
    typealias Model = FollowUserSheetModel
    typealias ViewModel = FollowUserFormModel
    
    static func get(state: Model) -> ViewModel {
        state.followUserForm
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.followUserForm = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .followUserForm(action)
    }
}

struct FollowUserSheet: View {
    var state: FollowUserSheetModel
    var send: (FollowUserSheetAction) -> Void
    
    var onAttemptFollow: () -> Void
    
    var failFollowError: String?
    var onDismissError: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: AppTheme.unit2) {
            if let user = state.user {
                ProfilePic(pfp: user.pfp, size: .large)
                
                Text(user.did.did)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            ValidatedFormField(
                alignment: .center,
                placeholder: "petname",
                field: state.followUserForm.petname,
                send: Address.forward(
                    send: send,
                    tag: { a in FollowUserSheetAction.followUserForm(.petnameField(a)) }
                ),
                caption: .text(state.petnameFieldCaption ?? "")
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(1)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            
            Spacer()
            
            Button(
                action: onAttemptFollow,
                label: {
                    if let petname = state.followUserForm.petname.validated {
                        Text("Follow \(petname.toPetname().markup)")
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
        .alert(
            isPresented: Binding(
                get: { failFollowError != nil },
                set: { _ in onDismissError() }
            )
        ) {
            Alert(
                title: Text("Failed to Follow User"),
                message: Text(failFollowError ?? "An unknown error occurred")
            )
        }
    }
}
