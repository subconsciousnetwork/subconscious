//
//  UserProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2023.
//

import Foundation
import SwiftUI

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
    let user: UserProfile
    let statistics: UserProfileStatistics
    let entries: [EntryStub]
    
    let onNavigateToNote: (MemoAddress) -> Void
    let onNavigateToUser: (MemoAddress) -> Void
    
    @State var selectedTab = 0
    
    func makeColumns() -> [TabbedColumnItem] {
        return [
            TabbedColumnItem(
                label: "Recent",
                view: Group {
                    ForEach(entries, id: \.id) { entry in
                        StoryPlainView(
                            story: StoryPlain(entry: entry),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                    Button(action: {}, label: { Text("More...") })
                }
            ),
            TabbedColumnItem(
                label: "Top",
                view: Group {
                    ForEach(entries, id: \.id) { entry in
                        StoryPlainView(
                            story: StoryPlain(entry: entry),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                    Button(action: {}, label: { Text("More...") })
                }
            ),
            TabbedColumnItem(
                label: "Following",
                view: Group {
                    ForEach(0..<30) {_ in
                        StoryUserView(story: StoryUser(user: user, statistics: statistics), action: { address, _ in onNavigateToUser(address) })
                    }
                    
                    Button(action: {}, label: { Text("View All") })
                }
            )
        ]
    }

    var body: some View {
        // Break this up so SwiftUI can actually typecheck
        let columns = self.makeColumns()
        
        VStack(alignment: .leading, spacing: 0) {
            BylineLgView(user: user, statistics: statistics)
            .padding(AppTheme.padding)
            
            TabbedColumnView(
                columns: columns,
                selectedColumnIndex: selectedTab,
                changeColumn: { index in
                    selectedTab = index
                }
            )
        }
        .navigationTitle(user.petname.verbatim)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            DetailToolbarContent(
                address: Slashlink(petname: user.petname).toPublicMemoAddress(),
                defaultAudience: .public,
                onTapOmnibox: {
                    
                }
            )
        })
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            user: UserProfile(
                petname: Petname("ben")!,
                pfp: "pfp-dog",
                bio: "Henlo world."
            ),
            statistics: UserProfileStatistics(
                noteCount: 123,
                backlinkCount: 64,
                followingCount: 19
            ),
            entries: UserProfileDetailModel.generateEntryStubs(petname: "ben", count: 10),
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") }
        )
    }
}
