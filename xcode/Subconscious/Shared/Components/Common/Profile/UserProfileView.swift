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

struct RecentTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onNavigateToNote: (Slashlink) -> Void
    
    var body: some View {
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
        } else {
            FabSpacerView()
        }
    }
}

struct FollowTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onNavigateToUser: (UserProfile) -> Void
    var onProfileAction: (UserProfile, UserProfileAction) -> Void
    
    var body: some View {
        
        ForEach(state.following) { follow in
            StoryUserView(
                story: follow,
                action: { _ in onNavigateToUser(follow.user) },
                profileAction: onProfileAction,
                onRefreshUser: {
                    guard let petname = follow.user.address.toPetname() else {
                        return
                    }
                    
                    send(.requestWaitForFollowedUserResolution(petname))
                }
            )
        }
        
        if state.following.count == 0 {
            EmptyStateView()
        } else {
            FabSpacerView()
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
    
    func columnLoading(label: String) -> TabbedColumnItem<FeedPlaceholderView> {
        TabbedColumnItem(
            label: label,
            view: FeedPlaceholderView()
        )
    }
    
    var columnRecent: TabbedColumnItem<RecentTabView> {
        TabbedColumnItem(
            label: "Notes",
            view: RecentTabView(
                state: state,
                send: send,
                onNavigateToNote: onNavigateToNote
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
                onProfileAction: onProfileAction
            )
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch state.loadingState {
                case .loading:
                    ProfileHeaderPlaceholderView()
                    
                    TabbedTwoColumnView(
                        columnA: columnLoading(label: "Notes"),
                        columnB: columnLoading(label: "Following"),
                        selectedColumnIndex: state.currentTabIndex,
                        changeColumn: { index in
                            send(.tabIndexSelected(index))
                        }
                    )
                    .edgesIgnoringSafeArea([.bottom])
                case .loaded:
                    if let user = state.user {
                        UserProfileHeaderView(
                            user: user,
                            statistics: state.statistics,
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
                        .padding(
                            .init([.top, .horizontal]),
                            AppTheme.padding
                        )
                    }
                    
                    TabbedTwoColumnView(
                        columnA: columnRecent,
                        columnB: columnFollowing,
                        selectedColumnIndex: state.currentTabIndex,
                        changeColumn: { index in
                            send(.tabIndexSelected(index))
                        }
                    )
                    .edgesIgnoringSafeArea([.bottom])
                case .notFound:
                    NotFoundView()
                    // extra padding to visually center the group
                        .padding(.bottom, AppTheme.unit * 24)
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
        .navigationTitle(state.user?.address.peer?.markup ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if let user = state.user,
               user.category == .ourself {
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
            
            if let address = state.address {
                DetailToolbarContent(
                    address: address,
                    defaultAudience: .public,
                    onTapOmnibox: {
                        send(.presentMetaSheet(true))
                    },
                    status: state.loadingState
                )
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
        .rename(state: state, send: send)
    }
}

// Only used _directly_ above
private extension View {
    func unfollow(
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
        self.modifier(UnfollowSheetModifier(state: state, send: send))
    }
    
    func follow(
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
        self.modifier(FollowSheetModifier(state: state, send: send))
    }
    
    func rename(
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
        self.modifier(RenameSheetModifier(state: state, send: send))
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
