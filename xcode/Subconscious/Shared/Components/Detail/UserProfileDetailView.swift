//
//  UserProfileDetailView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import os
import SwiftUI
import ObservableStore
import Combine

/// Display a user profile detail view.
/// Used to browse users entries and list of petnames.
struct UserProfileDetailView: View {
    @StateObject private var store = Store(
        state: UserProfileDetailModel(),
        environment: AppEnvironment.default
    )
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileDetailView"
    )

    var description: UserProfileDetailDescription
    var notify: (UserProfileDetailNotification) -> Void
    
    func onNavigateToNote(address: MemoAddress) {
        notify(.requestDetail(.from(address: address, fallback: "")))
    }
    
    func onNavigateToUser(user: UserProfile) {
        notify(.requestDetail(.profile(
            UserProfileDetailDescription(address: user.address)
        )))
    }
    
    func onProfileAction(user: UserProfile, action: UserProfileAction) {
        switch (action) {
        case .requestFollow:
            store.send(.requestFollow)
        case .requestUnfollow:
            store.send(.requestUnfollow)
        case .editOwnProfile:
            store.send(.presentEditProfile(true))
        }
    }

    var body: some View {
        UserProfileView(
            state: store.state,
            send: store.send,
            onNavigateToNote: self.onNavigateToNote,
            onNavigateToUser: self.onNavigateToUser,
            onProfileAction: self.onProfileAction
        )
        .onAppear {
            // When an editor is presented, refresh if stale.
            // This covers the case where the editor might have been in the
            // background for a while, and the content changed in another tab.
            store.send(
                UserProfileDetailAction.appear(
                    description.address
                )
            )
        }
    }
}

/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum UserProfileDetailNotification: Hashable {
    case requestDetail(MemoDetailDescription)
}

/// A description of a user profile that can be used to set up the user
/// profile's internal state.
struct UserProfileDetailDescription: Hashable {
    var address: MemoAddress
}

enum UserProfileDetailAction {
    case appear(MemoAddress)
    case populate(UserProfileContentResponse)
    case failedToPopulate(String)
    
    case tabIndexSelected(Int)
    
    case presentMetaSheet(Bool)
    case presentFollowSheet(Bool)
    case presentUnfollowConfirmation(Bool)
    case presentEditProfile(Bool)
    
    case metaSheet(UserProfileDetailMetaSheetAction)
    case followUserSheet(FollowUserSheetAction)
    case editProfileSheet(EditProfileSheetAction)
    
    case fetchFollowingStatus(Did)
    case populateFollowingStatus(Bool)
    
    case requestFollow
    case attemptFollow
    case failFollow(error: String)
    case dismissFailFollowError
    case succeedFollow(did: Did, petname: Petname)
    
    case requestUnfollow
    case attemptUnfollow
    case failUnfollow(error: String)
    case dismissFailUnfollowError
    case succeedUnfollow(did: Did, petname: Petname)
    
    case requestEditProfile
    case succeedEditProfile
    case failEditorProfile(error: String)
}

struct UserProfileStatistics: Equatable, Codable, Hashable {
    let noteCount: Int
    let backlinkCount: Int
    let followingCount: Int
}

enum UserCategory: Equatable, Codable, Hashable, CaseIterable {
    case human
    case geist
    case you
}

struct UserProfile: Equatable, Codable, Hashable {
    let did: Did
    let petname: Petname
    let preferredPetname: String?
    let address: MemoAddress
    let pfp: String
    let bio: String
    let category: UserCategory
}

struct EditProfileSheetCursor: CursorProtocol {
    typealias Model = UserProfileDetailModel
    typealias ViewModel = EditProfileSheetModel
    
    static func get(state: Model) -> ViewModel {
        state.editProfileSheet
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.editProfileSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .editProfileSheet(action)
    }
}

// MARK: Model
struct UserProfileDetailModel: ModelProtocol {
    typealias Action = UserProfileDetailAction
    typealias Environment = AppEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileDetail"
    )
    
    var loadingState = LoadingState.loading
    
    var metaSheet: UserProfileDetailMetaSheetModel = UserProfileDetailMetaSheetModel()
    var followUserSheet: FollowUserSheetModel = FollowUserSheetModel()
    var editProfileSheet: EditProfileSheetModel = EditProfileSheetModel()
    var failFollowErrorMessage: String?
    var failUnfollowErrorMessage: String?
    
    var selectedTabIndex = 0
    var isMetaSheetPresented = false
    var isFollowSheetPresented = false
    var isUnfollowConfirmationPresented = false
    var isEditProfileSheetPresented = false
    
    var user: UserProfile? = nil
    var isFollowingUser: Bool = false
    
    var recentEntries: [EntryStub] = []
    var topEntries: [EntryStub] = []
    var following: [StoryUser] = []
    
    var statistics: UserProfileStatistics? = nil
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .metaSheet(let action):
            return UserProfileDetailMetaSheetCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .followUserSheet(let action):
            return FollowUserSheetCursor.update(
                state: state,
                action: action,
                environment: FollowUserSheetEnvironment(addressBook: environment.addressBook)
            )
        case .editProfileSheet(let action):
            return EditProfileSheetCursor.update(
                state: state,
                action: action,
                environment: EditProfileSheetEnvironment()
            )
        case .appear(let address):
            let fxRoot: AnyPublisher<UserProfileContentResponse, Error> =
            Func.run {
                if let petname = address.petname {
                    return environment.userProfile.requestUserProfilePublisher(petname: petname)
                } else {
                    return environment.userProfile.requestOwnProfilePublisher()
                }
            }
            
            let fx: Fx<UserProfileDetailAction> =
            fxRoot
                .map { content in
                    UserProfileDetailAction.populate(content)
                }
                .catch { error in
                    Just(UserProfileDetailAction.failedToPopulate(error.localizedDescription))
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .populate(let content):
            var model = state
            model.user = content.profile
            model.statistics = content.statistics
            model.recentEntries = content.entries
            model.topEntries = content.entries
            model.following = content.following
            model.isFollowingUser = content.isFollowingUser
            model.loadingState = .loaded
            
            return update(
                state: model,
                actions: [
                    .fetchFollowingStatus(content.profile.did)
                ],
                environment: environment
            )
            
        case .failedToPopulate(let error):
            var model = state
            model.loadingState = .notFound
            logger.error("Failed to fetch profile: \(error)")
            return Update(state: model)
            
        case .tabIndexSelected(let index):
            var model = state
            model.selectedTabIndex = index
            return Update(state: model)
            
        case .presentMetaSheet(let presented):
            var model = state
            model.isMetaSheetPresented = presented
            return Update(state: model)
            
        case .presentFollowSheet(let presented):
            var model = state
            model.isFollowSheetPresented = presented
            return Update(state: model)
            
            // MARK: Following status
        case .fetchFollowingStatus(let did):
            let fx: Fx<UserProfileDetailAction> =
            environment.addressBook
                .isFollowingUserPublisher(did: did)
                .map { following in
                    UserProfileDetailAction.populateFollowingStatus(following)
                }
                .catch { error in
                    logger.error("Failed to fetch following status for \(did): \(error)")
                    return Just(UserProfileDetailAction.populateFollowingStatus(false))
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .populateFollowingStatus(let following):
            var model = state
            model.isFollowingUser = following
            return Update(state: model)
            
            // MARK: Following
        case .requestFollow:
            return update(state: state, action: .presentFollowSheet(true), environment: environment)
            
        case .attemptFollow:
            guard let did = state.followUserSheet.followUserForm.did.validated else {
                return Update(state: state)
            }
            guard let petname = state.followUserSheet.followUserForm.petname.validated else {
                return Update(state: state)
            }
            
            let fx: Fx<UserProfileDetailAction> =
            environment.addressBook
                .followUserPublisher(did: did, petname: petname, preventOverwrite: true)
                .map({ _ in
                    UserProfileDetailAction.succeedFollow(did: did, petname: petname)
                })
                .catch { error in
                    Just(UserProfileDetailAction.failFollow(error: error.localizedDescription))
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedFollow(let did, _):
            return update(
                state: state,
                actions: [
                    .presentFollowSheet(false),
                    .fetchFollowingStatus(did)
                ],
                environment: environment
            )
            
        case .failFollow(error: let error):
            var model = state
            model.failFollowErrorMessage = error
            return Update(state: model)
            
        case .dismissFailFollowError:
            var model = state
            model.failFollowErrorMessage = nil
            return Update(state: model)
            
            // MARK: Unfollowing
        case .presentUnfollowConfirmation(let presented):
            var model = state
            model.isUnfollowConfirmationPresented = presented
            return Update(state: model)
            
        case .requestUnfollow:
            return update(state: state, action: .presentUnfollowConfirmation(true), environment: environment)
            
        case .attemptUnfollow:
            guard let petname = state.user?.petname, let did = state.user?.did else {
                return Update(state: state)
            }
            
            let fx: Fx<UserProfileDetailAction> =
            environment.addressBook
                .unfollowUserPublisher(did: did)
                .map({ _ in
                        .succeedUnfollow(did: did, petname: petname)
                })
                .catch({ error in
                    Just(
                        .failUnfollow(error: error.localizedDescription)
                    )
                })
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedUnfollow(let did, _):
            return update(
                state: state,
                actions: [
                    .presentUnfollowConfirmation(false),
                    .fetchFollowingStatus(did)
                ],
                environment: environment
            )
            
        case .failUnfollow(error: let error):
            var model = state
            model.failUnfollowErrorMessage = error
            return Update(state: model)
            
        case .dismissFailUnfollowError:
            var model = state
            model.failUnfollowErrorMessage = nil
            return Update(state: model)
            
        case .presentEditProfile(let presented):
            var model = state
            model.isEditProfileSheetPresented = presented
            let profile = UserProfileEntry(
                version: UserProfileEntry.currentVersion,
                preferredName: state.user?.preferredPetname,
                bio: state.user?.bio,
                profilePictureUrl: state.user?.pfp
            )
            return update(
                state: model,
                action: .editProfileSheet(.populate(profile)),
                environment: environment
            )
            
        case .requestEditProfile:
            let profile = UserProfileEntry(
                version: UserProfileEntry.currentVersion,
                preferredName: state.editProfileSheet.nicknameField.validated?.verbatim,
                bio: state.editProfileSheet.bioField.validated,
                profilePictureUrl: state.editProfileSheet.pfpUrlField.validated?.absoluteString
            )
            
            let fx: Fx<UserProfileDetailAction> = Future.detached {
                try await environment.userProfile.writeOurProfile(profile: profile)
                return UserProfileDetailAction.succeedEditProfile
            }
            .recover { error in
                return UserProfileDetailAction.failEditorProfile(error: error.localizedDescription)
            }
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedEditProfile:
            logger.info("Edited")
            guard let address = state.user?.address else {
                return Update(state: state)
            }
            
            var model = state
            model.isEditProfileSheetPresented = false
            
            return update(state: model, action: .appear(address), environment: environment)
            
        case .failEditorProfile(let error):
            logger.error("Failed to edit: \(error)")
            return Update(state: state)
        }
    }
}
