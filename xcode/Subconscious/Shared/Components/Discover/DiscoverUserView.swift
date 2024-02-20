//
//  DiscoverUserView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 20/2/2024.
//

import SwiftUI

/// Show a user card in a feed format
struct DiscoverUserView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var suggestion: UserDiscoverySuggestion
    var action: (Slashlink) -> Void
    
    var pendingFollow: Bool = false
    var onFollow: (NeighborRecord) -> Void
    
    var body: some View {
        Button(
            action: {
                action(suggestion.neighbor.address)
            },
            label: {
            VStack(alignment: .leading, spacing: AppTheme.unit3) {
                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: AppTheme.unit2) {
                        ProfilePic(pfp: .generated(suggestion.neighbor.identity), size: .medium)
                        
                        Text("\(suggestion.neighbor.name.description)")
                            .italic()
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    if pendingFollow {
                        ProgressView()
                    } else {
                        Button(
                            action: {
                                onFollow(suggestion.neighbor)
                            },
                            label: {
                                Text("Follow")
                                    .font(.caption)
                            }
                        )
                        .buttonStyle(DiscoverActionButtonStyle())
                    }
                }
                .padding(
                    EdgeInsets(
                        top: AppTheme.unit3,
                        leading: AppTheme.unit3,
                        bottom: 0,
                        trailing: AppTheme.unit3
                    )
                )
                
                if let bio = suggestion.neighbor.bio,
                   bio.hasVisibleContent {
                    Text(verbatim: bio.text)
                        .padding(.horizontal, AppTheme.unit3)
                }
                
                Divider()
                
                HStack {
                    Text("Followed by \(suggestion.followedBy.map { f in f.petname.markup }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: AppTheme.unit3,
                        bottom: AppTheme.unit3,
                        trailing: AppTheme.unit3
                    )
                )
            }
        })
        .buttonStyle(
            EntryListRowButtonStyle(
                color: .secondaryBackground,
                padding: 0
            )
        )
    }
}

struct DiscoverUserView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Spacer()
            DiscoverUserView(
                suggestion: UserDiscoverySuggestion(
                    neighbor: NeighborRecord(
                        petname: Petname.dummyData(),
                        identity: Did.dummyData(),
                        address: Slashlink.dummyData(),
                        peer: Petname.dummyData()
                    ),
                    followedBy: []
                ),
                action: { _ in },
                onFollow: { _ in }
            )
            
            Spacer()
        }
        .background(.secondary)
        .frame(maxHeight: .infinity)
    }
}

