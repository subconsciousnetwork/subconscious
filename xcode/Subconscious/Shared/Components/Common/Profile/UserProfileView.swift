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

struct UserProfileView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    
    let onNavigateToNote: (MemoAddress) -> Void
    let onNavigateToUser: (UserProfile) -> Void
    
    let onProfileAction: (UserProfile, UserProfileAction) -> Void
    
    var body: some View {
        let columnRecent = TabbedColumnItem(
            label: "Recent",
            view: Group {
                if let user = state.user {
                    ForEach(state.recentEntries, id: \.id) { entry in
                        StoryEntryView(
                            story: StoryEntry(
                                author: user,
                                entry: entry
                            ),
                            action: { address, _ in onNavigateToNote(address) }
                        )
                    }
                }
            }
        )
        
        let columnTop = TabbedColumnItem(
            label: "Top",
            view: Group {
                if let user = state.user {
                    ForEach(state.topEntries, id: \.id) { entry in
                        StoryEntryView(
                            story: StoryEntry(
                                author: user,
                                entry: entry
                            ),
                            action: { address, _ in onNavigateToNote(address) }
                        )
                    }
                }
            }
        )
         
        let columnFollowing = TabbedColumnItem(
            label: "Following",
            view: Group {
                ForEach(state.following, id: \.user.did) { follow in
                    StoryUserView(
                        story: follow,
                        action: { _, _ in onNavigateToUser(follow.user) },
                        profileAction: onProfileAction
                    )
                }
            }
        )
        
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
                        }
                    )
                    .padding(AppTheme.padding)
                }
                
                TabbedThreeColumnView(
                    columnA: columnRecent,
                    columnB: columnTop,
                    columnC: columnFollowing,
                    selectedColumnIndex: state.selectedTabIndex,
                    changeColumn: { index in
                        send(.tabIndexSelected(index))
                    }
                )
            case .notFound:
                Text("Not found")
            }
        }
        .navigationTitle(state.user?.petname.verbatim ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if let user = state.user {
                switch (user.category) {
                case .human, .geist:
                    DetailToolbarContent(
                        address: Slashlink(petname: user.petname).toPublicMemoAddress(),
                        defaultAudience: .public,
                        onTapOmnibox: {
                            send(.presentMetaSheet(true))
                        }
                    )
                case .you:
                    DetailToolbarContent(
                        address: Slashlink.ourProfile.toPublicMemoAddress(),
                        defaultAudience: .public,
                        onTapOmnibox: {
                            send(.presentMetaSheet(true))
                        }
                    )
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
                if let user = state.user {
                    FollowUserSheet(
                        state: state.followUserSheet,
                        send: Address.forward(
                            send: send,
                            tag: FollowUserSheetCursor.tag
                        ),
                        user: user,
                        onAttemptFollow: {
                            send(.attemptFollow)
                        },
                        failFollowError: state.failFollowErrorMessage,
                        onDismissError: {
                            send(.dismissFailFollowError)
                        }
                    )
                }
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
              "Unfollow \(state.user?.petname.markup ?? "user")?",
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
                        onEditProfile: {
                            send(.requestEditProfile)
                        }
                    )
                }
            }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            state: UserProfileDetailModel(isFollowSheetPresented: true),
            send: { _ in },
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") },
            onProfileAction: { user, action in print("profile action") }
        )
    }
}
