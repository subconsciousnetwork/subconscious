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
    var count: Int
    
    var body: some View {
        HStack(spacing: AppTheme.unit) {
            Text("\(count)").bold()
            Text(label).foregroundColor(.secondary)
        }
    }
}

struct RecentTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onNavigateToNote: (Slashlink) -> Void
    
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
            send(.refresh)
        }
    }
}

struct TopTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    
    var body: some View {
        ScrollView {
            EmptyStateView()
        }
        .refreshable {
            send(.refresh)
        }
    }
}

struct FollowTabView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    var onNavigateToUser: (UserProfile) -> Void
    var onProfileAction: (UserProfile, UserProfileAction) -> Void
    
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
            send(.refresh)
        }
    }
}

struct UserProfileView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    
    var onNavigateToNote: (Slashlink) -> Void
    var onNavigateToUser: (UserProfile) -> Void
    
    var onProfileAction: (UserProfile, UserProfileAction) -> Void
    
    var columnRecent: TabbedColumnItem<RecentTabView> {
        TabbedColumnItem(
            label: "Recent",
            view: RecentTabView(
                state: state,
                send: send,
                onNavigateToNote: onNavigateToNote
            )
        )
    }
    var columnTop: TabbedColumnItem<TopTabView> {
        TabbedColumnItem(
            label: "Top",
            view: TopTabView(state: state, send: send)
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
        VStack(alignment: .leading, spacing: 0) {
            switch (state.loadingState) {
            case .loading:
                ProgressView()
            case .loaded:
                if let user = state.user {
                    UserProfileHeaderView(
                        user: user,
                        statistics: state.statistics,
                        isFollowingUser: state.isFollowingUser,
                        action: { action in
                            onProfileAction(user, action)
                        },
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
        .navigationTitle(state.user?.nickname.verbatim ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if let user = state.user {
                DetailToolbarContent(
                    address: user.address,
                    defaultAudience: .public,
                    onTapOmnibox: {
                        send(.presentMetaSheet(true))
                    }
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
        .editProfile(state: state, send: send)
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
        state: UserProfileDetailModel,
        send: @escaping (UserProfileDetailAction) -> Void
    ) -> some View {
      self.modifier(EditProfileSheetModifier(state: state, send: send))
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
                        guard let petname = form.petname.validated else {
                            return
                        }
                        
                        send(.attemptFollow(did, petname))
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
              "Unfollow \(state.unfollowCandidate?.nickname.markup ?? "user")?",
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
    let state: UserProfileDetailModel
    let send: (UserProfileDetailAction) -> Void
    
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
                        guard let petname = form.petname.validated else {
                            return
                        }
                        
                        send(.attemptFollow(did, petname))
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
            state: UserProfileDetailModel(),
            send: { _ in },
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") },
            onProfileAction: { user, action in print("profile action") }
        )
    }
}
