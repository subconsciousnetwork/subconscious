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
    @ObservedObject var store: Store<UserProfileDetailModel>
    var notify: (UserProfileDetailNotification) -> Void
    
    var body: some View {
        if let user = store.state.user,
           let recent = store.state.recentEntries {
            ForEach(recent) { entry in
                StoryEntryView(
                    story: StoryEntry(
                        entry: entry,
                        author: user
                    ),
                    onRequestDetail: { address, excerpt in
                        notify(
                            .requestDetail(
                                .from(
                                    address: address,
                                    fallback: excerpt
                                )
                            )
                        )
                    },
                    onLink: { link in
                        notify(.requestFindLinkDetail(link))
                    }
                )
                
                Divider()
            }
            .transition(.opacity)
            
            if recent.count == 0 {
                let name = user.address.peer?.markup ?? "This user"
                EmptyStateView(
                    message: "\(name) has not posted any notes yet."
                )
            } else {
                FabSpacerView()
            }
        }
    }
}

struct FollowTabView: View {
    @ObservedObject var store: Store<UserProfileDetailModel>
    var notify: (UserProfileDetailNotification) -> Void
    
    var body: some View {
        if let following = store.state.following {
            ForEach(following) { follow in
                StoryUserView(
                    story: follow,
                    action: { address in
                        notify(
                            .requestNavigateToProfile(address)
                        )
                    },
                    profileAction: { user, action in
                        store.send(
                            UserProfileDetailAction.from(user, action)
                        )
                    },
                    onRefreshUser: {
                        store.send(
                            .requestWaitForFollowedUserResolution(follow.entry.petname)
                        )
                    }
                )
                
                Divider()
            }
            .transition(.opacity)
            
            if following.count == 0 {
                let name = store.state.user?.address.peer?.markup ?? "This user"
                EmptyStateView(
                    message: "\(name) does not follow anyone."
                )
            } else {
                FabSpacerView()
            }
        }
    }
}

struct UserProfileView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    static let resetScrollTargetId: Int = 0
    
    private var state: UserProfileDetailModel {
        store.state
    }
    private var send: (UserProfileDetailAction) -> Void {
        store.send
    }
    
    var notify: (UserProfileDetailNotification) -> Void
    
    func onRefresh() async {
        app.send(.syncAll)
        await store.refresh()
    }
    
    func columnLoading(label: String) -> TabbedColumnItem<StoryListPlaceholderView> {
        TabbedColumnItem(
            label: label,
            view: StoryListPlaceholderView()
        )
    }
    
    var columnRecent: TabbedColumnItem<RecentTabView> {
        TabbedColumnItem(
            label: "Notes",
            view: RecentTabView(
                store: store,
                notify: notify
            )
        )
    }
        
    var columnFollowing: TabbedColumnItem<FollowTabView> {
        TabbedColumnItem(
            label: "Following",
            view: FollowTabView(
                store: store,
                notify: notify
            )
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch state.loadingState {
                case .loading, .loaded:
                    if let user = state.user {
                        UserProfileHeaderView(
                            user: user,
                            statistics: state.statistics,
                            action: { action in
                                store.send(UserProfileDetailAction.from(user, action))
                            },
                            onTapStatistics: {
                                send(
                                    .tabIndexSelected(
                                        UserProfileDetailModel.followingTabIndex
                                    )
                                )
                            }
                        )
                        .id(Self.resetScrollTargetId)
                        .disabled(state.loadingState != .loaded)
                        .padding(
                            .init([.top, .horizontal]),
                            AppTheme.padding
                        )
                    } else {
                        ProfileHeaderPlaceholderView()
                    }
                    
                    // Only render these if we have data, each subcomponent fetches its own data
                    // so discard the value.
                    if let _ = state.recentEntries,
                       let _ = state.following {
                        TabbedTwoColumnView(
                            columnA: columnRecent,
                            columnB: columnFollowing,
                            selectedColumnIndex: state.currentTabIndex,
                            changeColumn: { index in
                                send(.tabIndexSelected(index))
                            }
                        )
                    } else {
                        TabbedTwoColumnView(
                            columnA: columnLoading(label: "Notes"),
                            columnB: columnLoading(label: "Following"),
                            selectedColumnIndex: state.currentTabIndex,
                            changeColumn: { index in
                                send(.tabIndexSelected(index))
                            }
                        )
                    }
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
                    status: store.state.loadingState
                )
            } else {
                DetailToolbarContent(
                    defaultAudience: .public,
                    onTapOmnibox: {
                        send(.presentMetaSheet(true))
                    },
                    status: store.state.loadingState
                )
            }
        })
        .metaSheet(store: store)
        .follow(store: store)
        .unfollow(store: store)
        .editProfile(app: app, store: store)
        .rename(store: store)
    }
}

// Only used _directly_ above
private extension View {
    func unfollow(
        store: Store<UserProfileDetailModel>
    ) -> some View {
        self.modifier(UnfollowSheetModifier(store: store))
    }
    
    func follow(
        store: Store<UserProfileDetailModel>
    ) -> some View {
        self
            .modifier(FollowSheetModifier(store: store))
            .modifier(FollowNewUserSheetModifier(store: store))
    }
    
    func rename(
        store: Store<UserProfileDetailModel>
    ) -> some View {
        self.modifier(RenameSheetModifier(store: store))
    }
    
    func metaSheet(
        store: Store<UserProfileDetailModel>
    ) -> some View {
        self.modifier(UserProfileDetialMetaSheetModifier(store: store))
    }
    
    func editProfile(
        app: Store<AppModel>,
        store: Store<UserProfileDetailModel>
    ) -> some View {
        self.modifier(EditProfileSheetModifier(app: app, store: store))
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
            notify: { _ in }
        )
    }
}
