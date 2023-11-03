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
    
    case submit
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
            
            let initialName: Petname.Name? = Func.run {
                switch (user.ourFollowStatus) {
                case .following(let name):
                    return name
                case .notFollowing:
                    return user.nickname ?? user.address.petname?.leaf
                }
            }
            
            guard let bestFollowName = initialName else {
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
            
        // Notifications
        case .submit:
            return Update(state: state)
        }
    }
}

struct RenameUserSheetCursor: CursorProtocol {
    typealias Model = UserProfileDetailModel
    typealias ViewModel = FollowUserSheetModel
    
    static func get(state: Model) -> ViewModel {
        state.renameUserSheet
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.renameUserSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .submit:
            return .attemptRename
        default:
            return .renameUserSheet(action)
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
        switch action {
        case .submit:
            return .attemptFollow
        default:
            return .followUserSheet(action)
        }
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
    var store: ViewStore<FollowUserSheetModel>
    var label: Text
    
    var caption: String {
        let name = store.state.user?.address.toPetname()?.markup ?? "user"
        return store.state.petnameFieldCaption ?? String(localized: "Choose a nickname for \(name)")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: AppTheme.unit2) {
                ValidatedFormField(
                    alignment: .center,
                    placeholder: "petname",
                    field: store.viewStore(
                        get: \.followUserForm.petname,
                        tag: { a in FollowUserSheetAction.followUserForm(.petnameField(a)) }
                    ),
                    caption: caption
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(1)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                
                Spacer()
                
                if let user = store.state.user,
                   let name = store.state.followUserForm.petname.validated {
                    HStack(spacing: AppTheme.padding) {
                        ProfilePic(pfp: user.pfp, size: .large)
                        PetnameView(name: .unknown(user.address, name))
                    }
                    
                    Spacer()
                }
                
                Button(
                    action: { store.send(.submit) },
                    label: {
                        label
                    }
                )
                .buttonStyle(PillButtonStyle())
                .disabled(!store.state.followUserForm.petname.isValid)
            }
        }
        .padding(AppTheme.padding)
        .presentationDetents([.fraction(0.33)])
    }
}
