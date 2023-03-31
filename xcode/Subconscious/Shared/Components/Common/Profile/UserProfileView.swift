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
    let entries: [EntryStub]
    
    let onNavigateToNote: (MemoAddress) -> Void
    let onNavigateToUser: (MemoAddress) -> Void
    
    var body: some View {
        let columnA = TabbedColumnItem(
            label: "Recent",
            view:
                Group {
                    ForEach(entries, id: \.id) { entry in
                        StoryPlainView(
                            story: StoryPlain(entry: entry),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                    Button(action: {}, label: { Text("More...") })
                }
            
        )
        
        let columnB = TabbedColumnItem(
            label: "Top",
            view:
                Group {
                    ForEach(entries, id: \.id) { entry in
                        StoryPlainView(
                            story: StoryPlain(entry: entry),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                    Button(action: {}, label: { Text("More...") })
                }
            
        )
         
        let columnC = TabbedColumnItem(
            label: "Following",
            view:
                Group {
                    ForEach(0..<30) {_ in
                        StoryUserView(
                            story: StoryUser.dummyData(),
                            action: { address, _ in onNavigateToUser(address) }
                        )
                    }
                    
                    Button(action: {}, label: { Text("View All") })
                }
            
        )
        
        VStack(alignment: .leading, spacing: 0) {
            if let user = state.user {
                UserProfileHeaderView(user: user, statistics: state.statistics, following: false)
                    .padding(AppTheme.padding)
            }
            
            TabbedThreeColumnView(
                columnA: columnA,
                columnB: columnB,
                columnC: columnC,
                selectedColumnIndex: state.selectedTabIndex,
                changeColumn: { index in
                    send(.tabIndexSelected(index))
                }
            )
        }
        .navigationTitle(state.user?.petname.verbatim ?? "unknown")
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
                followingUser: state.followingUser,
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
            entries: UserProfileDetailModel.generateEntryStubs(petname: "ben", count: 10),
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") }
        )
    }
}
