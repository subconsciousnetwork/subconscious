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
            UserProfileDetailDescription(
                did: user.did,
                user: user.petname,
                spherePath: description.spherePath + [user.petname]
            )
        )))
    }
    
    func onProfileAction(user: UserProfile, action: UserProfileAction) {
        switch (action) {
        case .requestFollow:
            store.send(.requestFollow)
        case .requestUnfollow:
            store.send(.requestUnfollow)
        case .editOwnProfile:
            Self.logger.warning("Editing profiles is not supported yet, doing nothing")
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
                    description.did,
                    description.user,
                    description.spherePath
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
    var did: Did
    var user: Petname
    var spherePath: [Petname]
}

enum UserProfileDetailAction: Hashable {
    case appear(Did, Petname, SpherePath)
    case populate(UserProfileContentPayload)
    case failedToPopulate(String)
    
    case tabIndexSelected(Int)
    
    case presentMetaSheet(Bool)
    case presentFollowSheet(Bool)
    case presentUnfollowConfirmation(Bool)
    
    case metaSheet(UserProfileDetailMetaSheetAction)
    case followUserSheet(FollowUserSheetAction)
    
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
    let pfp: String
    let bio: String
    let category: UserCategory
}

typealias SpherePath = [Petname]

// MARK: Model
struct UserProfileDetailModel: ModelProtocol {
    typealias Action = UserProfileDetailAction
    typealias Environment = AppEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileDetailModel"
    )
    
    var loadingState = LoadingState.loading
    
    var metaSheet: UserProfileDetailMetaSheetModel = UserProfileDetailMetaSheetModel()
    var followUserSheet: FollowUserSheetModel = FollowUserSheetModel()
    var failFollowErrorMessage: String?
    var failUnfollowErrorMessage: String?
    
    var selectedTabIndex = 0
    var isMetaSheetPresented = false
    var isFollowSheetPresented = false
    var isUnfollowConfirmationPresented = false
    
    var user: UserProfile? = nil
    var isFollowingUser: Bool = false
    
    var recentEntries: [EntryStub] = []
    var topEntries: [EntryStub] = []
    var following: [StoryUser] = []

    var spherePath: SpherePath = []
    
    var statistics: UserProfileStatistics? = nil
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileDetailModel"
    )

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
        case .appear(let petname, let spherePath):
            var model = state
            model.spherePath = spherePath
            
            let fx: Fx<UserProfileDetailAction> =
                environment.userProfile
                .getUserProfileAsync(petname: petname)
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
            model.recentEntries = content.entries
            model.topEntries = content.entries
            model.following = content.following
            model.isFollowingUser = content.isFollowingUser
            model.loadingState = .loaded
            
            return update(
                state: model,
                actions: [
                    .fetchFollowingStatus(user.did)
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
        }
    }
}
