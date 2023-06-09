//
//  UserProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2023.
//

import SwiftUI
import ObservableStore
import Combine

struct ProfileStatisticView: View {
    var label: String
    var count: Int?
    
    var countLabel: String {
        count.map { c in String(c) } ?? "-"
    }
    
    var body: some View {
        HStack(spacing: AppTheme.unit) {
            Text(countLabel).bold()
            Text(label).foregroundColor(.secondary)
        }
    }
}

struct LoadingTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            StoryPlaceholderView(bioWidthFactor: 1.2)
            StoryPlaceholderView(delay: 0.25, nameWidthFactor: 0.7, bioWidthFactor: 0.9)
            StoryPlaceholderView(delay: 0.5, nameWidthFactor: 0.7, bioWidthFactor: 0.5)
        }
        .refreshable {
            await onRefresh()
        }
    }
}


struct RecentTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onNavigateToNote: (Slashlink) -> Void
    var onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            if let user = state.user {
                ForEach(state.recentEntries) { entry in
                    StoryEntryView(
                        story: StoryEntry(
                            author: user,
                            entry: entry
                        ),
                        action: { address, _ in onNavigateToNote(address) }
                    )
                }
            }
            
            if state.recentEntries.count == 0 {
                EmptyStateView()
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}

struct TopTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            EmptyStateView()
        }
        .refreshable {
            await onRefresh()
        }
    }
}

struct FollowTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onNavigateToUser: (UserProfile) -> Void
    var onProfileAction: (UserProfile, UserProfileAction) -> Void
    var onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            ForEach(state.following) { follow in
                StoryUserView(
                    story: follow,
                    action: { _, _ in onNavigateToUser(follow.user) },
                    profileAction: onProfileAction
                )
            }
            
            if state.following.count == 0 {
                EmptyStateView()
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}

struct UserProfileView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    private var state: UserProfileDetailModel {
        store.state
    }
    private var send: (UserProfileDetailAction) -> Void {
        store.send
    }
    
    var onNavigateToNote: (Slashlink) -> Void
    var onNavigateToUser: (UserProfile) -> Void
    
    var onProfileAction: (UserProfile, UserProfileAction) -> Void
    var onRefresh: () async -> Void
    
    func columnLoading(label: String) -> TabbedColumnItem<LoadingTabView> {
        TabbedColumnItem(
            label: label,
            view: LoadingTabView(
                state: state,
                send: send,
                onRefresh: onRefresh
            )
        )
    }
    
    var columnRecent: TabbedColumnItem<RecentTabView> {
        TabbedColumnItem(
            label: "Recent",
            view: RecentTabView(
                state: state,
                send: send,
                onNavigateToNote: onNavigateToNote,
                onRefresh: onRefresh
            )
        )
    }
    var columnTop: TabbedColumnItem<TopTabView> {
        TabbedColumnItem(
            label: "Top",
            view: TopTabView(
                state: state,
                send: send,
                onRefresh: onRefresh
            )
        )
    }
        
    var columnFollowing: TabbedColumnItem<FollowTabView> {
        TabbedColumnItem(
            label: "Following",
            view: FollowTabView(
                state: state,
                send: send,
                onNavigateToUser: onNavigateToUser,
                onProfileAction: onProfileAction,
                onRefresh: onRefresh
            )
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let user = state.user {
                UserProfileHeaderView(
                    user: user,
                    statistics: state.statistics,
                    isFollowingUser: state.isFollowingUser,
                    action: { action in
                        onProfileAction(user, action)
                    },
                    hideActionButton: state.loadingState != .loaded,
                    onTapStatistics: {
                        send(
                            .tabIndexSelected(
                                UserProfileDetailModel.followingTabIndex
                            )
                        )
                    }
                )
                .padding(AppTheme.padding)
            }
            
            switch state.loadingState {
            case .loading:
                TabbedThreeColumnView(
                    columnA: columnLoading(label: "Recent"),
                    columnB: columnLoading(label: "Top"),
                    columnC: columnLoading(label: "Following"),
                    selectedColumnIndex: state.currentTabIndex,
                    changeColumn: { index in
                        send(.tabIndexSelected(index))
                    }
                )
            case .loaded:
                TabbedThreeColumnView(
                    columnA: columnRecent,
                    columnB: columnTop,
                    columnC: columnFollowing,
                    selectedColumnIndex: state.currentTabIndex,
                    changeColumn: { index in
                        send(.tabIndexSelected(index))
                    }
                )
            case .notFound:
                Text("Not found")
            }
        }
        .navigationTitle(state.user?.address.peer?.markup ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if let user = state.user {
                DetailToolbarContent(
                    address: user.address,
                    defaultAudience: .public,
                    onTapOmnibox: {
                        send(.presentMetaSheet(true))
                    },
                    status: state.loadingState
                )
                if user.category == .you {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(
                            action: {
                                send(.presentFollowNewUserFormSheet(true))
                            },
                            label: {
                                Image(systemName: "person.badge.plus")
                            }
                        )
                    }
                }
            } else {
                DetailToolbarContent(
                    defaultAudience: .public,
                    onTapOmnibox: {
                        send(.presentMetaSheet(true))
                    }
                )
            }
        })
        .metaSheet(state: state, send: send)
        .follow(state: state, send: send)
        .unfollow(state: state, send: send)
        .editProfile(app: app, store: store)
        .followNewUser(state: state, send: send)
    }
}

// Only used _directly_ above
private extension View {
    func unfollow(
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
        self.modifier(UnfollowModifier(state: state, send: send))
    }
    
    func follow(
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
        self.modifier(FollowModifier(state: state, send: send))
    }
    
    func metaSheet(
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
        self.modifier(MetaSheetModifier(state: state, send: send))
    }
    
    func editProfile(
        app: Store<AppModel>,
        store: Store<UserProfileDetailModel>
    ) -> some View {
        self.modifier(EditProfileSheetModifier(app: app, store: store))
    }
    
    func followNewUser(
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
        self.modifier(FollowNewUserSheetModifier(state: state, send: send))
    }
}

private struct MetaSheetModifier: ViewModifier {
    let state: UserProfileDetailModel
    let send: (UserProfileDetailAction) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: Binding(
                    get: { state.isMetaSheetPresented },
                    send: send,
                    tag: UserProfileDetailAction.presentMetaSheet
                )
            ) {
                UserProfileDetailMetaSheet(
                    state: state.metaSheet,
                    profile: state,
                    isFollowingUser: state.isFollowingUser,
                    send: Address.forward(
                        send: send,
                        tag: UserProfileDetailMetaSheetCursor.tag
                    )
                )
            }
    }
}

private struct FollowModifier: ViewModifier {
    let state: UserProfileDetailModel
    let send: (UserProfileDetailAction) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: Binding(
                    get: { state.isFollowSheetPresented },
                    send: send,
                    tag: UserProfileDetailAction.presentFollowSheet
                )
            ) {
                FollowUserSheet(
                    state: state.followUserSheet,
                    send: Address.forward(
                        send: send,
                        tag: FollowUserSheetCursor.tag
                    ),
                    onAttemptFollow: {
                        let form = state.followUserSheet.followUserForm
                        guard let did = form.did.validated else {
                            return
                        }
                        guard let name = form.petname.validated else {
                            return
                        }
                        
                        send(.attemptFollow(did, name.toPetname()))
                    },
                    failFollowError: state.failFollowErrorMessage,
                    onDismissError: {
                        send(.dismissFailFollowError)
                    }
                )
            }
    }
}

private struct UnfollowModifier: ViewModifier {
  let state: UserProfileDetailModel
  let send: (UserProfileDetailAction) -> Void

  func body(content: Content) -> some View {
    content
      .alert(
          isPresented: Binding(
              get: { state.failUnfollowErrorMessage != nil },
              set: { _ in send(.dismissFailUnfollowError) }
          )
      ) {
          Alert(
              title: Text("Failed to Unfollow User"),
              message: Text(state.failUnfollowErrorMessage ?? "An unknown error occurred")
          )
      }
      .confirmationDialog(
          "Are you sure?",
          isPresented:
              Binding(
                  get: { state.isUnfollowConfirmationPresented },
                  set: { _ in send(.presentUnfollowConfirmation(false)) }
              )
      ) {
          Button(
              "Unfollow \(state.unfollowCandidate?.displayName ?? "user")?",
              role: .destructive
          ) {
              send(.attemptUnfollow)
          }
      } message: {
          Text("You cannot undo this action")
      }
  }
}

private struct EditProfileSheetModifier: ViewModifier {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<UserProfileDetailModel>
    private var state: UserProfileDetailModel {
        store.state
    }
    private var send: (UserProfileDetailAction) -> Void {
        store.send
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: Binding(
                    get: { state.isEditProfileSheetPresented },
                    send: send,
                    tag: UserProfileDetailAction.presentEditProfile
                )
            ) {
                if let user = state.user {
                    EditProfileSheet(
                        state: state.editProfileSheet,
                        send: Address.forward(
                            send: send,
                            tag: EditProfileSheetCursor.tag
                        ),
                        user: user,
                        statistics: state.statistics,
                        failEditProfileMessage: state.failEditProfileMessage,
                        onEditProfile: {
                            send(.requestEditProfile)
                        },
                        onCancel: {
                            send(.presentEditProfile(false))
                        },
                        onDismissError: {
                            send(.dismissEditProfileError)
                        }
                    )
                }
            }
            .onReceive(
                store.actions.compactMap(AppAction.from),
                perform: app.send
            )
    }
}

private struct FollowNewUserSheetModifier: ViewModifier {
    let state: UserProfileDetailModel
    let send: (UserProfileDetailAction) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: Binding(
                    get: { state.isFollowNewUserFormSheetPresented },
                    send: send,
                    tag: UserProfileDetailAction.presentFollowNewUserFormSheet
                )
            ) {
                FollowNewUserFormSheetView(
                    state: state.followNewUserFormSheet,
                    send: Address.forward(
                        send: send,
                        tag: FollowNewUserFormSheetCursor.tag
                    ),
                    did: state.user?.did,
                    onAttemptFollow: {
                        let form = state.followNewUserFormSheet.form
                        guard let did = form.did.validated else {
                            return
                        }
                        guard let name = form.petname.validated else {
                            return
                        }
                        
                        send(.attemptFollow(did, name.toPetname()))
                    },
                    onCancel: { send(.presentFollowNewUserFormSheet(false)) },
                    onDismissFailFollowError: { send(.dismissFailFollowError) }
                )
            }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            app: Store(state: AppModel(), environment: AppEnvironment()),
            store: Store(
                state: UserProfileDetailModel(),
                environment: UserProfileDetailModel.Environment()
            ),
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") },
            onProfileAction: { user, action in print("profile action") },
            onRefresh: { }
        )
    }
}
