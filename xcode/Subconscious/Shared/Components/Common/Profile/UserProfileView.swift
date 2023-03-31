//
//  UserProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2023.
//

import Foundation
import SwiftUI
import ObservableStore

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
    let onNavigateToUser: (MemoAddress) -> Void
    
    var body: some View {
        let columnRecent = TabbedColumnItem(
            label: "Recent",
            view:
                Group {
                    ForEach(state.recentEntries, id: \.id) { entry in
                        StoryPlainView(
                            story: StoryPlain(entry: entry),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                }
            
        )
        
        let columnTop = TabbedColumnItem(
            label: "Top",
            view:
                Group {
                    ForEach(state.topEntries, id: \.id) { entry in
                        StoryPlainView(
                            story: StoryPlain(entry: entry),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                }
            
        )
         
        let columnFollowing = TabbedColumnItem(
            label: "Following",
            view:
                Group {
                    ForEach(state.following, id: \.user.did) { follow in
                        StoryUserView(
                            story: follow,
                            action: { address, _ in onNavigateToUser(address) }
                        )
                    }
                }
            
        )
        
        VStack(alignment: .leading, spacing: 0) {
            if let user = state.user {
                UserProfileHeaderView(
                    user: user,
                    statistics: state.statistics,
                    isFollowingUser: state.isFollowingUser
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
        }
        .navigationTitle(state.user?.petname.verbatim ?? "loading...")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if let user = state.user {
                DetailToolbarContent(
                    address: Slashlink(petname: user.petname).toPublicMemoAddress(),
                    defaultAudience: .public,
                    onTapOmnibox: {
                        send(.presentMetaSheet(true))
                    }
                )
            }
        })
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

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            state: UserProfileDetailModel(isMetaSheetPresented: false),
            send: { _ in },
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") }
        )
    }
}
