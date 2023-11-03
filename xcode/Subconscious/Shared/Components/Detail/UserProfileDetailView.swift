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
    @ObservedObject var app: Store<AppModel>
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
    
    var body: some View {
        UserProfileView(
            app: app,
            store: store,
            notify: notify
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
        .onReceive(
            store.actions.compactMap(UserProfileDetailAction.toAppAction),
            perform: app.send
        )
        .onReceive(
            app.actions.compactMap(UserProfileDetailAction.from),
            perform: store.send
        )
        .onReceive(store.actions) { action in
            UserProfileDetailAction.logger.debug(
                "\(String(describing: action))"
            )
        }
    }
}

/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum UserProfileDetailNotification: Hashable {
    case requestNavigateToProfile(_ address: Slashlink)
    case requestDetail(MemoDetailDescription)
    case requestFindLinkDetail(
        context: ResolvedAddress,
        link: SubSlashlinkLink
    )
}

extension UserProfileDetailAction {
    static func toAppAction(_ action: Self) -> AppAction? {
        switch action {
        case let .succeedResolveFollowedUser(petname, cid):
            return .notifySucceedResolveFollowedUser(petname: petname, cid: cid)
        case let .succeedUnfollow(identity, petname):
            return .notifySucceedUnfollow(identity: identity, petname: petname)
        case .failRename:
            return AppAction.pushToast(message: "Failed to rename user")
        case .failUnfollow:
            return AppAction.pushToast(message: "Failed to unfollow user")
        case .failEditProfile:
            return AppAction.pushToast(message: "Failed to edit profile")
        case .failFollow:
            return AppAction.pushToast(message: "Failed to follow user")
        default:
            return nil
        }
    }
}

extension UserProfileDetailAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .completeIndexPeers(let results):
            return .completeIndexPeers(results)
        case .succeedIndexOurSphere:
            return .refresh(forceSync: false)
        case .succeedRecoverOurSphere:
            return .refresh(forceSync: false)
        default:
            return nil
        }
    }
}

/// A description of a user profile that can be used to set up the user
/// profile's internal state.
struct UserProfileDetailDescription: Hashable {
    var address: Slashlink
    var initialTabIndex: Int = UserProfileDetailModel.recentEntriesTabIndex
}

extension UserProfileDetailAction {
    static func from(_ user: UserProfile, _ action: UserProfileAction) -> UserProfileDetailAction {
        switch (action) {
        case .requestFollow:
            return .requestFollow(user)
        case .requestUnfollow:
            return .requestUnfollow(user)
        case .requestRename:
            return .requestRename(user)
        case .editOwnProfile:
            return .presentEditProfile(true)
        }
    }
}

enum UserProfileDetailAction {
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileDetailAction"
    )

    case appear(Slashlink, Int)
    case refresh(forceSync: Bool)
    case populate(UserProfileContentResponse)
    case failedToPopulate(String)
    
    case tabIndexSelected(Int)
    
    case presentMetaSheet(Bool)
    case presentFollowSheet(Bool)
    case presentUnfollowConfirmation(Bool)
    case presentEditProfile(Bool)
    case presentFollowNewUserFormSheet(Bool)
    case presentRenameSheet(Bool)
    
    case metaSheet(UserProfileDetailMetaSheetAction)
    case followUserSheet(FollowUserSheetAction)
    case renameUserSheet(FollowUserSheetAction)
    case editProfileSheet(EditProfileSheetAction)
    case followNewUserFormSheet(FollowNewUserFormSheetAction)
    
    case requestFollow(UserProfile)
    case attemptFollow(Did, Petname)
    case failFollow(error: String)
    case succeedFollow(_ petname: Petname)
    
    case requestRename(UserProfile)
    case attemptRename(from: Petname, to: Petname)
    case failRename(error: String)
    case succeedRename(from: Petname, to: Petname)
    
    case requestWaitForFollowedUserResolution(_ petname: Petname)
    case succeedResolveFollowedUser(petname: Petname, cid: Cid?)
    case failResolveFollowedUser(_ message: String)
    
    case requestUnfollow(UserProfile)
    case attemptUnfollow
    case failUnfollow(error: String)
    case succeedUnfollow(identity: Did, petname: Petname)
    
    case requestEditProfile
    case failEditProfile(error: String)
    case succeedEditProfile
    
    case completeIndexPeers(_ results: [PeerIndexResult])
}

struct UserProfileStatistics: Equatable, Codable, Hashable {
    let noteCount: Int
    let backlinkCount: Int
    let followingCount: Int
}

enum UserCategory: Equatable, Codable, Hashable, CaseIterable {
    case human
    case geist
    case ourself
}

struct UserProfile: Equatable, Codable, Hashable {
    let did: Did
    let nickname: Petname.Name?
    let address: Slashlink
    let pfp: ProfilePicVariant
    let bio: UserProfileBio?
    let category: UserCategory
    let ourFollowStatus: UserProfileFollowStatus
    let aliases: [Petname]
    
    var isFollowedByUs: Bool {
        ourFollowStatus.isFollowing
    }
    
    // A string that identifies this user.
    var displayName: String {
        switch (ourFollowStatus) {
        case .following(let name):
            return name.description
        case _:
            // Rare edgecase, only occurs if the address is a DID
            guard let name = nickname?.toPetname() ?? address.petname else {
                return "(unknown)"
            }
            
            return "\(name)"
        }
        
    }
    
    func overrideAddress(_ address: Slashlink) -> UserProfile {
        UserProfile(
            did: did,
            nickname: nickname,
            address: address,
            pfp: pfp,
            bio: bio,
            category: category,
            ourFollowStatus: ourFollowStatus,
            aliases: aliases
        )
    }
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

extension Store<UserProfileDetailModel> {
    func refresh() async {
        guard let address = state.user?.address else {
            return
        }
        
        // Ensure updates are sent on the main thread
        let send = { (action) -> Void in
            Task {
                @MainActor in self.send(action)
            }
        }
        
        do {
            let res = try await Self.Model.refresh(
                address: address,
                environment: self.environment
            )
            
            send(.populate(res))
        } catch {
            send(.failedToPopulate(error.localizedDescription))
        }
    }
}

extension UserProfileDetailModel {
     static func refresh(
        address: Slashlink,
        environment: UserProfileDetailModel.Environment
    ) async throws -> UserProfileContentResponse {
        return try await Func.run {
            if let petname = address.toPetname() {
                return try await environment
                    .userProfile
                    .loadFullProfileData(address: Slashlink(petname: petname))
            } else {
                return try await environment
                    .userProfile
                    .loadOurFullProfileData()
            }
        }
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
    static let followingTabIndex: Int = 1
    
    var loadingState = LoadingState.loading
    
    var metaSheet = UserProfileDetailMetaSheetModel()
    var followUserSheet = FollowUserSheetModel()
    var renameUserSheet = FollowUserSheetModel()
    var followNewUserFormSheet = FollowNewUserFormSheetModel()
    var editProfileSheet = EditProfileSheetModel()
    
    // This view can be invoked with an initial tab focused
    // but if the user has changed the tab we should remember that across profile refreshes
    private var initialTabIndex: Int = Self.recentEntriesTabIndex
    private var selectedTabIndex: Int? = nil
    
    var currentTabIndex: Int {
        selectedTabIndex ?? initialTabIndex
    }
    
    var isMetaSheetPresented = false
    var isFollowSheetPresented = false
    var isFollowNewUserFormSheetPresented = false
    var isUnfollowConfirmationPresented = false
    var isEditProfileSheetPresented = false
    var isRenameSheetPresented = false
    
    var address: Slashlink? = nil
    var user: UserProfile? = nil
    
    var recentEntries: [EntryStub] = []
    var following: [StoryUser] = []
    
    var statistics: UserProfileStatistics? = nil
    var unfollowCandidate: UserProfile? = nil
    var renameCandidate: Petname? = nil
    
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
        case .renameUserSheet(let action):
            return RenameUserSheetCursor.update(
                state: state,
                action: action,
                environment: FollowUserSheetEnvironment(addressBook: environment.addressBook)
            )
        case .followNewUserFormSheet(let action):
            return FollowNewUserFormSheetCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .editProfileSheet(let action):
            return EditProfileSheetCursor.update(
                state: state,
                action: action,
                environment: EditProfileSheetEnvironment()
            )
        // MARK: Lifecycle
        // The forceSync parameter for this action dictates whether .syncAll is dispatched to the
        // at the same time. See UserProfileView.
        case .refresh(_):
            return refresh(
                state: state,
                environment: environment
            )
        case .appear(let address, let initialTabIndex):
            return appear(
                state: state,
                environment: environment,
                address: address,
                initialTabIndex: initialTabIndex
            )
        case .populate(let content):
            return populate(
                state: state,
                environment: environment,
                content: content
            )
        case .failedToPopulate(let error):
            return failedToPopulate(
                state: state,
                environment: environment,
                error: error
            )
        case .tabIndexSelected(let index):
            return tabIndexSelected(
                state: state,
                environment: environment,
                index: index
            )
            // MARK: Presentation
        case .presentMetaSheet(let isPresented):
            return presentMetaSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .presentFollowNewUserFormSheet(let isPresented):
            return presentFollowNewUserFormSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .presentFollowSheet(let isPresented):
            return presentFollowSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        // MARK: Following
        case .requestFollow(let user):
            return requestFollow(
                state: state,
                environment: environment,
                user: user
            )
        case .attemptFollow(let did, let petname):
            return attemptFollow(
                state: state,
                environment: environment,
                did: did,
                petname: petname
            )
        case let .succeedFollow(petname):
            return succeedFollow(
                state: state,
                environment: environment,
                petname: petname
            )
        case .failFollow(let error):
            return failFollow(
                state: state,
                environment: environment,
                error: error
            )
        // MARK: Rename
        case .presentRenameSheet(let isPresented):
            return presentRenameSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .requestRename(let user):
            return requestRename(
                state: state,
                environment: environment,
                user: user
            )
        case let .attemptRename(from, to):
            return attemptRename(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case let .succeedRename(from, to):
            return succeedRename(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .failRename(let error):
            return failRename(
                state: state,
                environment: environment,
                error: error
            )
        case let .requestWaitForFollowedUserResolution(petname):
            return requestWaitForFollowedUserResolution(
                state: state,
                environment: environment,
                petname: petname
            )
        case .succeedResolveFollowedUser:
            return succeedResolveFollowedUser(
                state: state,
                environment: environment
            )
        case .failResolveFollowedUser(let error):
            return failResolveFollowedUser(
                state: state,
                environment: environment,
                error: error
            )
            // MARK: Unfollowing
        case .presentUnfollowConfirmation(let isPresented):
            return presentUnfollowConfirmation(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .requestUnfollow(let user):
            return requestUnfollow(
                state: state,
                environment: environment,
                user: user
            )
        case .attemptUnfollow:
            return attemptUnfollow(
                state: state,
                environment: environment
            )
        case let .succeedUnfollow(identity, petname):
            return succeedUnfollow(
                state: state,
                environment: environment,
                identity: identity,
                petname: petname
            )
        case let .failUnfollow(error):
            return failUnfollow(
                state: state,
                environment: environment,
                error: error
            )
        // MARK: Edit Profile
        case .presentEditProfile(let isPresented):
            return presentEditProfile(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .requestEditProfile:
            return requestEditProfile(
                state: state,
                environment: environment
            )
        case .succeedEditProfile:
            return succeedEditProfile(
                state: state,
                environment: environment
            )
        case .failEditProfile(let error):
            return failEditProfile(
                state: state,
                environment: environment,
                error: error
            )
        case .completeIndexPeers(let results):
            return completeIndexPeers(
                state: state,
                environment: environment,
                results: results
            )
        }
    }
    
    static func refresh(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        guard state.loadingState != .loading else {
            // While initially loading we might be prompted by a notification to refresh _again_
            // This could happen when indexing completes in the BG or after a sync
            logger.log("Attempted to refresh while already loading, doing nothing.")
            return Update(state: state)
        }
        
        guard let user = state.user else {
            return Update(state: state)
        }
        
        return update(
            state: state,
            action: .appear(user.address, state.initialTabIndex),
            environment: environment
        )
    }
    
    static func appear(
        state: Self,
        environment: Environment,
        address: Slashlink,
        initialTabIndex: Int
    ) -> Update<Self> {
        var model = state
        model.initialTabIndex = initialTabIndex
        // We might be passed some basic profile data
        // we can use this in the loading state for a preview
        model.address = address
        
        let fx: Fx<UserProfileDetailAction> = Future.detached {
            logger.log("Begin loading profile \(address)")
            return try await Self.refresh(address: address, environment: environment)
        }
        .map { content in
            UserProfileDetailAction.populate(content)
        }
        .recover { error in
            UserProfileDetailAction.failedToPopulate(
                error.localizedDescription
            )
        }
        .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func populate(
        state: Self,
        environment: Environment,
        content: UserProfileContentResponse
    ) -> Update<Self> {
        var model = state
        model.user = content.profile
        model.statistics = content.statistics
        model.recentEntries = content.recentEntries
        model.following = content.following
        model.loadingState = .loaded
        
        return Update(state: model).animation(.default)
    }
    
    static func failedToPopulate(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        var model = state
        model.loadingState = .notFound
        logger.error("Failed to fetch profile: \(error)")
        return Update(state: model)
    }
    
    static func tabIndexSelected(
        state: Self,
        environment: Environment,
        index: Int
    ) -> Update<Self> {
        var model = state
        model.selectedTabIndex = index
        
        return Update(state: model).animation(.easeOutCubic())
    }
    
    static func presentMetaSheet(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isMetaSheetPresented = isPresented
        return Update(state: model)
    }
    
    static func presentFollowNewUserFormSheet(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isFollowNewUserFormSheetPresented = isPresented
        
        if isPresented {
            return update(
                state: model,
                action: .followNewUserFormSheet(.form(.reset)),
                environment: environment
            )
        }
        
        return Update(state: model)
    }
    
    static func presentFollowSheet(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isFollowSheetPresented = isPresented
        return Update(state: model)
    }
    
    static func requestFollow(
        state: Self,
        environment: Environment,
        user: UserProfile
    ) -> Update<Self> {
        return update(
            state: state,
            actions: [
                .presentFollowSheet(true),
                .followUserSheet(.populate(user))
            ],
            environment: environment
        )
    }
    
    static func attemptFollow(
        state: Self,
        environment: Environment,
        did: Did,
        petname: Petname
    ) -> Update<Self> {
        let fx: Fx<UserProfileDetailAction> =
        environment.addressBook
            .followUserPublisher(
                did: did,
                petname: petname,
                preventOverwrite: true
            )
            .map({ _ in
                UserProfileDetailAction.succeedFollow(petname)
            })
            .recover { error in
                .failFollow(
                    error: error.localizedDescription
                )
            }
            .eraseToAnyPublisher()
        
        // Dimiss sheet immediately
        return update(
            state: state,
            actions: [
                .presentFollowNewUserFormSheet(false),
                .presentFollowSheet(false)
            ],
            environment: environment
        ).mergeFx(fx)
    }
    
    static func succeedFollow(
        state: Self,
        environment: Environment,
        petname: Petname
    ) -> Update<Self> {
        var actions: [UserProfileDetailAction] = [
            .presentFollowSheet(false),
            .presentFollowNewUserFormSheet(false),
            .refresh(forceSync: true),
            .requestWaitForFollowedUserResolution(petname)
        ]
        
        // Refresh our profile & show the following list if we followed someone new
        // This matters if we used the manual "Follow User" form
        if let user = state.user {
            if user.category == .ourself {
                actions.append(.tabIndexSelected(Self.followingTabIndex))
            }
        }
        
        return update(
            state: state,
            actions: actions,
            environment: environment
        )
    }
    
    static func failFollow(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        var model = state
        model.isFollowSheetPresented = false
        model.isFollowNewUserFormSheetPresented = false
        return Update(state: model)
    }
    
    static func presentRenameSheet(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isRenameSheetPresented = isPresented
        return Update(state: model)
    }
    
    static func requestRename(
        state: Self,
        environment: Environment,
        user: UserProfile
    ) -> Update<Self> {
        var model = state
        
        guard case let .following(name) = user.ourFollowStatus else {
            logger.error("Cannot rename a user we do not follow")
            return Update(state: state)
        }
        
        model.renameCandidate = name.toPetname()
        
        return update(
            state: model,
            actions: [
                .presentRenameSheet(true),
                .followUserSheet(.populate(user))
            ],
            environment: environment
        )
    }
    
    static func attemptRename(
        state: Self,
        environment: Environment,
        from: Petname,
        to: Petname
    ) -> Update<Self> {
        let fx: Fx<UserProfileDetailAction> =
        Future.detached {
            let did = try await environment.addressBook.unfollowUser(petname: from)
            try await environment.addressBook.followUser(did: did, petname: to)
            
            return .succeedRename(from: from, to: to)
        }
        .recover { error in
            .failRename(error: error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        // Dimiss sheet immediately
        var model = state
        model.isRenameSheetPresented = false
        return Update(state: state, fx: fx)
    }
    
    static func succeedRename(
        state: Self,
        environment: Environment,
        from: Petname,
        to: Petname
    ) -> Update<Self> {
        var model = state
        model.renameCandidate = nil
        
        return update(
            state: model,
            actions: [
                .presentRenameSheet(false),
                .refresh(forceSync: true)
            ],
            environment: environment
        )
    }
    
    static func failRename(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        var model = state
        model.isRenameSheetPresented = false
        return Update(state: model)
    }
    
    static func requestWaitForFollowedUserResolution(
        state: Self,
        environment: Environment,
        petname: Petname
    ) -> Update<Self> {
        let fx: Fx<UserProfileDetailAction> = environment.addressBook
            .waitForPetnameResolutionPublisher(petname: petname)
            .map { cid in
                Action.succeedResolveFollowedUser(petname: petname, cid: cid)
            }
            .recover { error in
                Action.failResolveFollowedUser(error.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        return update(
            state: state,
            action: .refresh(forceSync: true),
            environment: environment
        ).mergeFx(fx)
    }
    
    static func succeedResolveFollowedUser(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        
        // We should not sync after resolution because resolution happens via syncing
        // in the first place.
        update(
            state: state,
            action: .refresh(forceSync: false),
            environment: environment
        )
    }
    
    static func failResolveFollowedUser(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        // Skip sync here, any retry/refresh logic is triggered by tapping on this
        // user in the following list.
        
        logger.log("Failed to resolve followed user: \(error)")
        return update(
            state: state,
            action: .refresh(forceSync: false),
            environment: environment
        )
    }
    
    static func presentUnfollowConfirmation(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isUnfollowConfirmationPresented = isPresented
        return Update(state: model)
    }
    
    static func requestUnfollow(
        state: Self,
        environment: Environment,
        user: UserProfile
    ) -> Update<Self> {
        var model = state
        model.unfollowCandidate = user
        
        return update(
            state: model,
            action: .presentUnfollowConfirmation(true),
            environment: environment
        )
    }
    
    static func attemptUnfollow(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        guard let candidate = state.unfollowCandidate else {
            return Update(state: state)
        }
        
        switch (candidate.ourFollowStatus) {
        case .notFollowing:
            return Update(state: state)
        case .following(let name):
            let petname = name.toPetname()
            let fx: Fx<UserProfileDetailAction> = environment.addressBook
                .unfollowUserPublisher(petname: petname)
                .map({ identity in
                    Action.succeedUnfollow(identity: identity, petname: petname)
                })
                .recover({ error in
                    Action.failUnfollow(error: error.localizedDescription)
                })
                .eraseToAnyPublisher()
            
            // Dimiss confirmation immediately
            var model = state
            model.isUnfollowConfirmationPresented = false
            return Update(state: state, fx: fx)
        }
    }
    
    static func succeedUnfollow(
        state: Self,
        environment: Environment,
        identity: Did,
        petname: Petname
    ) -> Update<Self> {
        logger.log(
            "Unfollowed sphere",
            metadata: [
                "petname": petname.description,
                "did:": identity.description
            ]
        )
        return update(
            state: state,
            actions: [
                .presentUnfollowConfirmation(false),
                .refresh(forceSync: true)
            ],
            environment: environment
        )
    }
   
    static func failUnfollow(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        var model = state
        model.isUnfollowConfirmationPresented = false
        return Update(state: model)
    }
    
    static func presentEditProfile(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isEditProfileSheetPresented = isPresented
        
        let profile = UserProfileEntry(
            nickname: state.user?.nickname?.description,
            bio: state.user?.bio?.text
        )
        return update(
            state: model,
            action: .editProfileSheet(.populate(profile)),
            environment: environment
        )
    }
    
    static func requestEditProfile(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        let profile = UserProfileEntry(
            nickname: state.editProfileSheet.nicknameField.validated?.description,
            bio: state.editProfileSheet.bioField.validated?.text
        )
        
        let fx: Fx<UserProfileDetailAction> = Future.detached {
            try await environment.userProfile.writeOurProfile(
                profile: profile
            )
            return UserProfileDetailAction.succeedEditProfile
        }.recover({ error in
            UserProfileDetailAction.failEditProfile(
                error: error.localizedDescription
            )
        }).eraseToAnyPublisher()
        
        // Dimiss sheet immediately
        var model = state
        model.isEditProfileSheetPresented = false
        return Update(state: model, fx: fx)
    }
    
    static func succeedEditProfile(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        var model = state
        model.isEditProfileSheetPresented = false
        
        return update(
            state: model,
            action: .refresh(forceSync: true),
            environment: environment
        )
    }
    
    static func failEditProfile(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        var model = state
        model.isEditProfileSheetPresented = false
        return Update(state: model)
    }
    
    static func completeIndexPeers(
        state: Self,
        environment: Environment,
        results: [PeerIndexResult]
    ) -> Update<Self> {
        // Check if we're in the list of successfully indexed peers
        let shouldRefresh = results.contains(where: { result in
            switch (result) {
            case .success(let peer) where peer.identity == state.user?.did:
                return true
            default:
                return false
            }
        })
        
        guard shouldRefresh else {
            logger.log("Skipping refresh, we are not in the list of peers")
            return Update(state: state)
        }
        
        return update(
            state: state,
            action: .refresh(forceSync: false),
            environment: environment
        )
    }
}
