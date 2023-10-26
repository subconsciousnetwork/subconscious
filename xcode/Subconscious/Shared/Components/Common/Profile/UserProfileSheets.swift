//
//  UserProfileView+SheetModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 14/8/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct MetaSheetModifier: ViewModifier {
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
                    send: Address.forward(
                        send: send,
                        tag: UserProfileDetailMetaSheetCursor.tag
                    )
                )
            }
    }
}

struct FollowSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    var state: UserProfileDetailModel {
        store.state
    }
    
    var send: (UserProfileDetailAction) -> Void {
        store.send
    }
    
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
                        
                        send(.attemptFollow(did, name.toPetname(), .followUserSheet))
                    },
                    label: Text("Follow"),
                    failFollowError: state.failFollowErrorMessage,
                    onDismissError: {
                        send(.dismissFailFollowError)
                    }
                )
            }
    }
}

struct RenameSheetModifier: ViewModifier {
    let state: UserProfileDetailModel
    let send: (UserProfileDetailAction) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: Binding(
                    get: { state.isRenameSheetPresented },
                    send: send,
                    tag: UserProfileDetailAction.presentRenameSheet
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
                        guard let name = form.petname.validated else {
                            return
                        }
                        guard let candidate = state.renameCandidate else {
                            return
                        }
                        
                        send(.attemptRename(from: candidate, to: name.toPetname()))
                    },
                    label: Text("Rename"),
                    failFollowError: state.failRenameMessage,
                    onDismissError: {
                        send(.dismissFailRenameErrorMessage)
                    }
                )
            }
    }
}

struct UnfollowSheetModifier: ViewModifier {
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

struct EditProfileSheetModifier: ViewModifier {
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
            .onReceive(app.actions, perform: { action in
                switch (action) {
                case .completeIndexPeers(let results)
                    // Only refresh the view if the presented user was indexed
                    where results.contains(where: { result in
                        switch (result) {
                        case .success(let peer) where peer.identity == state.user?.did:
                            return true
                        default:
                            return false
                        }
                    }):
                    
                    store.send(.refresh(forceSync: false))
                    break
                case _:
                    break
                }
            })
    }
}

struct FollowNewUserSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    var state: UserProfileDetailModel {
        store.state
    }
    
    var send: (UserProfileDetailAction) -> Void {
        store.send
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isFollowNewUserFormSheetPresented,
                    tag: UserProfileDetailAction.presentFollowNewUserFormSheet
                )
            ) {
                FollowNewUserFormSheetView(
                    store: store.viewStore(
                        get: \.followNewUserFormSheet,
                        tag: FollowNewUserFormSheetCursor.tag
                    ),
                    did: state.user?.did
                )
            }
            
    }
}
