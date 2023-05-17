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
    
    func onNavigateToNote(address: Slashlink) {
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
            store.send(.requestFollow(user))
        case .requestUnfollow:
            store.send(.requestUnfollow(user))
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
                    description.address,
                    description.initialTabIndex
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
    var address: Slashlink
    var initialTabIndex: Int = UserProfileDetailModel.recentEntriesTabIndex
}

enum UserProfileDetailAction {
    case appear(Slashlink, Int)
    case refresh
    case populate(UserProfileContentResponse)
    case failedToPopulate(String)
    
    case tabIndexSelected(Int)
    
    case presentMetaSheet(Bool)
    case presentFollowSheet(Bool)
    case presentUnfollowConfirmation(Bool)
    case presentEditProfile(Bool)
    case presentFollowNewUserFormSheet(Bool)
    
    case metaSheet(UserProfileDetailMetaSheetAction)
    case followUserSheet(FollowUserSheetAction)
    case editProfileSheet(EditProfileSheetAction)
    case followNewUserFormSheet(FollowNewUserFormSheetAction)
    
    case fetchFollowingStatus(Did)
    case populateFollowingStatus(Bool)
    
    case requestFollow(UserProfile)
    case attemptFollow(Did, Petname)
    case failFollow(error: String)
    case dismissFailFollowError
    case succeedFollow
    
    case requestUnfollow(UserProfile)
    case attemptUnfollow
    case failUnfollow(error: String)
    case dismissFailUnfollowError
    case succeedUnfollow
    
    case requestEditProfile
    case failEditProfile(error: String)
    case dismissEditProfileError
    case succeedEditProfile
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
    let nickname: Petname
    let address: Slashlink
    let pfp: ProfilePicVariant
    let bio: UserProfileBio
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
    
    // MARK: Tab Indices
    static let recentEntriesTabIndex: Int = 0
    static let topEntriesTabIndex: Int = 1
    static let followingTabIndex: Int = 2
    
    var loadingState = LoadingState.loading
    
    var metaSheet: UserProfileDetailMetaSheetModel = UserProfileDetailMetaSheetModel()
    var followUserSheet: FollowUserSheetModel = FollowUserSheetModel()
    var followNewUserFormSheet: FollowNewUserFormSheetModel = FollowNewUserFormSheetModel()
    var editProfileSheet: EditProfileSheetModel = EditProfileSheetModel()
    var failFollowErrorMessage: String?
    var failUnfollowErrorMessage: String?
    var failEditProfileMessage: String?
    
    // This view can be invoked with an initial tab focused
    // but if the user has changed the tab we should remember that across profile refreshes
    private var initialTabIndex: Int = Self.recentEntriesTabIndex
    private var selectedTabIndex: Int? = nil
    
    var currentTabIndex: Int {
        get {
            selectedTabIndex ?? initialTabIndex
        }
    }
    
    var isMetaSheetPresented = false
    var isFollowSheetPresented = false
    var isFollowNewUserFormSheetPresented = false
    var isUnfollowConfirmationPresented = false
    var isEditProfileSheetPresented = false
    
    var user: UserProfile? = nil
    var isFollowingUser: Bool = false
    
    var recentEntries: [EntryStub] = []
    var following: [StoryUser] = []
    
    var statistics: UserProfileStatistics? = nil
    
    var unfollowCandidate: UserProfile? = nil
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        // MARK: Submodels
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
        case .followNewUserFormSheet(let action):
            return FollowNewUserFormSheetCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .editProfileSheet(let action):
            return EditProfileSheetCursor.update(
                state: state,
                action: action,
                environment: EditProfileSheetEnvironment()
            )
            
        // MARK: Lifecycle
        case .refresh:
            guard let user = state.user else {
                return Update(state: state)
            }
            
            return update(
                state: state,
                action: .appear(user.address, state.initialTabIndex),
                environment: environment
            )
            
        case .appear(let address, let initialTabIndex):
            var model = state
            model.initialTabIndex = initialTabIndex
            
            let fxRoot: AnyPublisher<UserProfileContentResponse, Error> =
            Func.run {
                if let petname = address.toPetname() {
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
            
            return Update(state: model, fx: fx)
            
        case .populate(let content):
            var model = state
            model.user = content.profile
            model.statistics = content.statistics
            model.recentEntries = content.recentEntries
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
            
            return Update(state: model).animation(.default)
            
        // MARK: Presentation
        case .presentMetaSheet(let presented):
            var model = state
            model.isMetaSheetPresented = presented
            
            return Update(state: model)
            
        case .presentFollowNewUserFormSheet(let presented):
            var model = state
            model.isFollowNewUserFormSheetPresented = presented
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
        case .requestFollow(let user):
            return update(
                state: state,
                actions: [
                    .presentFollowSheet(true),
                    .followUserSheet(.populate(user))
                ],
                environment: environment
            )
            
        case .attemptFollow(let did, let petname):
            let fx: Fx<UserProfileDetailAction> =
            environment.addressBook
                .followUserPublisher(did: did, petname: petname, preventOverwrite: true)
                .map({ _ in
                    UserProfileDetailAction.succeedFollow
                })
                .catch { error in
                    Just(UserProfileDetailAction.failFollow(error: error.localizedDescription))
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedFollow:
            var actions: [UserProfileDetailAction] = [
                .presentFollowSheet(false),
                .presentFollowNewUserFormSheet(false),
                .refresh
            ]
            
            // Refresh our profile & show the following list if we followed someone new
            // This matters if we used the manual "Follow User" form
            if let user = state.user {
                if user.category == .you {
                    actions.append(.tabIndexSelected(Self.followingTabIndex))
                }
            }
            
            return update(
                state: state,
                actions: actions,
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
            
        case .requestUnfollow(let user):
            var model = state
            model.unfollowCandidate = user
            
            return update(
                state: model,
                action: .presentUnfollowConfirmation(true),
                environment: environment
            )
            
        case .attemptUnfollow:
            guard let did = state.unfollowCandidate?.did else {
                return Update(state: state)
            }
            
            let fx: Fx<UserProfileDetailAction> =
            environment.addressBook
                .unfollowUserPublisher(did: did)
                .map({ _ in
                    .succeedUnfollow
                })
                .recover({ error in
                    .failUnfollow(error: error.localizedDescription)
                })
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedUnfollow:
            return update(
                state: state,
                actions: [
                    .presentUnfollowConfirmation(false),
                    .refresh
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
            
        // MARK: Edit Profile
        case .presentEditProfile(let presented):
            var model = state
            model.isEditProfileSheetPresented = presented
            
            let pfp: URL? = Func.run {
                switch (state.user?.pfp) {
                case .some(.url(let url)):
                    return url
                case _:
                    return nil
                }
            }
            
            let profile = UserProfileEntry(
                nickname: state.user?.nickname.verbatim,
                bio: state.user?.bio.verbatim,
                profilePictureUrl: pfp?.absoluteString
            )
            return update(
                state: model,
                action: .editProfileSheet(.populate(profile)),
                environment: environment
            )
            
        case .requestEditProfile:
            let profile = UserProfileEntry(
                nickname: state.editProfileSheet.nicknameField.validated?.verbatim,
                bio: state.editProfileSheet.bioField.validated,
                profilePictureUrl: state.editProfileSheet.pfpUrlField.validated?.absoluteString
            )
            
            let fx: Fx<UserProfileDetailAction> = Future.detached {
                try await environment.userProfile.writeOurProfile(profile: profile)
                return UserProfileDetailAction.succeedEditProfile
            }
            .recover { error in
                return UserProfileDetailAction.failEditProfile(error: error.localizedDescription)
            }
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedEditProfile:
            var model = state
            model.isEditProfileSheetPresented = false
            
            return update(
                state: model,
                action: .refresh,
                environment: environment
            )
            
        case .failEditProfile(let error):
            var model = state
            model.failEditProfileMessage = error
            return Update(state: model)
            
        case .dismissEditProfileError:
            var model = state
            model.failEditProfileMessage = nil
            return Update(state: model)
   
        }
    }
}
