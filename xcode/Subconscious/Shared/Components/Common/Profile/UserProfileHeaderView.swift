//
//  BylineLgView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation
import SwiftUI

enum ProfileActionButton {
    case follow
    case following
    case editProfile
}


struct UserProfileHeaderView: View {
    var user: UserProfile
    var statistics: UserProfileStatistics?
    
    var isFollowingUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit3) {
            HStack(alignment: .center, spacing: AppTheme.unit3) {
                ProfilePic(image: Image(user.pfp))
                
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.unit) {
                    switch (user.category) {
                    case .human:
                        PetnameBylineView(petname: user.petname)
                    case .geist:
                        PetnameBylineView(petname: user.petname)
                    case .you:
                        PetnameBylineView(petname: user.petname)
                        Text("(you)")
                            .foregroundColor(.secondary)
                    }
                    
                }
                
                Spacer()
                
                if user.category == .you {
                    Button(action: {}, label: {
                        Label("Edit Profile", systemImage: "pencil")
                    })
                    .buttonStyle(PillButtonStyle(size: .small))
                    .frame(maxWidth: 160)
                } else {
                    if isFollowingUser {
                        Button(action: {}, label: {
                            Label("Following", systemImage: "person.fill.checkmark")
                        })
                        .buttonStyle(GhostPillButtonStyle(size: .small))
                        .frame(maxWidth: 160)
                    } else {
                        Button(action: {}, label: {
                            Text("Follow")
                        })
                        .buttonStyle(PillButtonStyle(size: .small))
                        .frame(maxWidth: 160)
                    }
                }
            }
            
            if let statistics = statistics {
                HStack(spacing: AppTheme.unit2) {
                    ProfileStatisticView(label: "Notes", count: statistics.noteCount)
                    ProfileStatisticView(label: "Backlinks", count: statistics.backlinkCount)
                    ProfileStatisticView(label: "Following", count: statistics.followingCount)
                }
                .font(.caption)
                .foregroundColor(.primary)
            }
            
            Text(verbatim: user.bio)
        }
    }
}

struct BylineLgView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UserProfileHeaderView(
                user: UserProfile(did: Did("did:key:123")!, petname: Petname("ben")!, pfp: "pfp-dog", bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle.", category: .human),
                isFollowingUser: false
            )
            UserProfileHeaderView(
                user: UserProfile(did: Did("did:key:123")!, petname: Petname("ben")!, pfp: "pfp-dog", bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle.", category: .geist),
                statistics: UserProfileStatistics(noteCount: 123, backlinkCount: 64, followingCount: 19),
                isFollowingUser: true
            )
            UserProfileHeaderView(
                user: UserProfile(did: Did("did:key:123")!, petname: Petname("ben")!, pfp: "pfp-dog", bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle.", category: .you),
                isFollowingUser: false
            )
        }
    }
}
