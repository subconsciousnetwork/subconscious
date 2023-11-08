//
//  UnfollowUserSheet.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import Foundation
import SwiftUI
import ObservableStore

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
