//
//  UserProfileDetailView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

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

    var description: UserProfileDetailDescription
    var notify: (UserProfileDetailNotification) -> Void
    
    func onNavigateToNote(address: MemoAddress) {
        notify(.requestDetail(.from(address: address, fallback: "")))
    }
    
    func onNavigateToUser(address: MemoAddress) {
        notify(.requestDetail(.profile(UserProfileDetailDescription(address: address))))
    }
    
    func onProfileAction(user: UserProfile, action: UserProfileAction) {
        switch (action) {
        case .requestFollow:
            store.send(.requestFollow)
        case .requestUnfollow:
            store.send(.requestUnfollow)
        // TODO
        case .editOwnProfile:
            return
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
            store.send(UserProfileDetailAction.populate(UserProfile.dummyData(), UserProfileStatistics.dummyData()))
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
    case populate(UserProfile, UserProfileStatistics?)
    case tabIndexSelected(Int)
    
    case presentMetaSheet(Bool)
    case presentFollowSheet(Bool)
    case presentUnfollowConfirmation(Bool)
    
    case metaSheet(UserProfileDetailMetaSheetAction)
    case followUserSheet(FollowUserSheetAction)
    
    case fetchFollowingStatus(Did, Petname)
    case failedToUpdateFollowingStatus(String)
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

struct UserProfileDetailModel: ModelProtocol {
    typealias Action = UserProfileDetailAction
    typealias Environment = AppEnvironment
    
    var metaSheet: UserProfileDetailMetaSheetModel = UserProfileDetailMetaSheetModel()
    var followUserSheet: FollowUserSheetModel = FollowUserSheetModel()
    var failFollowErrorMessage: String?
    var failUnfollowErrorMessage: String?
    
    var selectedTabIndex = 0
    var isMetaSheetPresented = false
    var isFollowSheetPresented = false
    var isUnfollowConfirmationPresented = false
    
    var user: UserProfile? = UserProfile.dummyData()
    var isFollowingUser: Bool = false
    
    var recentEntries: [EntryStub] = []
    var topEntries: [EntryStub] = []
    var following: [StoryUser] = []
    
    var statistics: UserProfileStatistics? = UserProfileStatistics.dummyData()
    
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
                environment: FollowUserSheetEnvironment(addressBook: environment.data.addressBook)
            )
            
        case .populate(let user, let statistics):
            var model = state
            model.user = user
            model.statistics = statistics
            model.recentEntries = (0...10).map { _ in EntryStub.dummyData(petname: user.petname) }
            model.topEntries = (0...10).map { _ in EntryStub.dummyData(petname: user.petname) }
            model.following = (1...10).map { _ in StoryUser.dummyData() }
            
            return update(
                state: model,
                actions: [.fetchFollowingStatus(user.did, user.petname)],
                environment: environment
            )
            
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
            
        case .fetchFollowingStatus(let did, let petname):
            let fx: Fx<UserProfileDetailAction> =
            environment.data.addressBook.isFollowingUserAsync(did: did, petname: petname)
                .map { following in
                    UserProfileDetailAction.populateFollowingStatus(following)
                }
                .catch { err in
                    Just(UserProfileDetailAction.failedToUpdateFollowingStatus(err.localizedDescription))
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .failedToUpdateFollowingStatus(let error):
            return Update(state: state)
            
        case .populateFollowingStatus(let following):
            var model = state
            model.isFollowingUser = following
            return Update(state: model)
            
        
            
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
                environment.data.addressBook
                .followUserAsync(did: did, petname: petname, preventOverwrite: true)
                .map({ _ in
                    UserProfileDetailAction.succeedFollow(did: did, petname: petname)
                })
                .catch { error in
                    Just(UserProfileDetailAction.failFollow(error: error.localizedDescription))
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedFollow(let did, let petname):
            return update(
                state: state,
                actions: [
                    .presentFollowSheet(false),
                    .fetchFollowingStatus(did, petname)
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
            
        case .presentUnfollowConfirmation(let presented):
            var model = state
            model.isUnfollowConfirmationPresented = presented
            return Update(state: model)
            
        case .requestUnfollow:
            return update(state: state, action: .presentUnfollowConfirmation(true), environment: environment)
            
        case .attemptUnfollow:
            guard let did = state.followUserSheet.followUserForm.did.validated else {
                return Update(state: state)
            }
            guard let petname = state.followUserSheet.followUserForm.petname.validated else {
                return Update(state: state)
            }
            
            let fx: Fx<UserProfileDetailAction> =
            environment.data.addressBook
                .unfollowUserAsync(petname: petname)
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
            
        case .succeedUnfollow(let did, let petname):
            return update(
                state: state,
                actions: [
                    .presentUnfollowConfirmation(false),
                    .fetchFollowingStatus(did, petname)
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
