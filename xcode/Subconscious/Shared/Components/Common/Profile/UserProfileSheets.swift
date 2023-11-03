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
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isMetaSheetPresented,
                    tag: UserProfileDetailAction.presentMetaSheet
                )
            ) {
                UserProfileDetailMetaSheet(
                    store: store.viewStore(
                        get: \.metaSheet,
                        tag: UserProfileDetailMetaSheetCursor.tag
                    )
                )
            }
    }
}

struct FollowSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isFollowSheetPresented,
                    tag: UserProfileDetailAction.presentFollowSheet
                )
            ) {
                FollowUserSheet(
                    store: store.viewStore(
                        get: \.followUserSheet,
                        tag: FollowUserSheetCursor.tag
                    ),
                    label: Text("Follow")
                )
            }
    }
}

struct RenameSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isRenameSheetPresented,
                    tag: UserProfileDetailAction.presentRenameSheet
                )
            ) {
                FollowUserSheet(
                    store: store.viewStore(
                        get: \.renameUserSheet,
                        tag: RenameUserSheetCursor.tag
                    ),
                    label: Text("Rename")
                )
            }
    }
}

struct UnfollowSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Are you sure?",
                isPresented: store.binding(
                    get: \.isUnfollowConfirmationPresented,
                    tag: UserProfileDetailAction.presentUnfollowConfirmation
                )
            ) {
                Button(
                    "Unfollow \(store.state.unfollowCandidate?.displayName ?? "user")?",
                    role: .destructive
                ) {
                    store.send(.attemptUnfollow)
                }
            } message: {
                Text("You cannot undo this action")
            }
    }
}

struct EditProfileSheetModifier: ViewModifier {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isEditProfileSheetPresented,
                    tag: UserProfileDetailAction.presentEditProfile
                )
            ) {
                EditProfileSheet(
                    store: store.viewStore(
                        get: \.editProfileSheet,
                        tag: EditProfileSheetCursor.tag
                    )
                )
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
                        case .success(let peer) where peer.identity == store.state.user?.did:
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
                    )
                )
            }
            
    }
}
