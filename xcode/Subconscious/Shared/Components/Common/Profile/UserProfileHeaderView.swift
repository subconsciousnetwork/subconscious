//
//  UserProfileHeaderView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

enum UserProfileAction {
    case requestFollow
    case requestUnfollow
    case editOwnProfile
}

struct UserProfileHeaderView: View {
    var user: UserProfile
    var statistics: UserProfileStatistics?
    
    var isFollowingUser: Bool
    var action: (UserProfileAction) -> Void = { _ in }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit3) {
            HStack(alignment: .center, spacing: AppTheme.unit3) {
                if let url = URL(string: user.pfp) {
                    ProfilePic(url: url)
                }
            
                PetnameBylineView(petname: Petname(user.preferredPetname ?? "") ?? user.petname)
                
                Spacer()
                
                Button(
                    action: {
                        switch (user.category, isFollowingUser) {
                        case (.you, _):
                            action(.editOwnProfile)
                        case (_, true):
                            action(.requestUnfollow)
                        case (_, false):
                            action(.requestFollow)
                        }
                    },
                    label: {
                        switch (user.category, isFollowingUser) {
                        case (.you, _):
                            Label("Edit Profile", systemImage: AppIcon.edit.systemName)
                        case (_, true):
                            Label("Following", systemImage: AppIcon.following.systemName)
                        case (_, false):
                            Text("Follow")
                        }
                    }
                )
                .buttonStyle(GhostPillButtonStyle(size: .small))
                .frame(maxWidth: 160)
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
                user: UserProfile(
                    did: Did("did:key:123")!,
                    petname: Petname("ben")!,
                    preferredPetname: nil,
                    address: Slashlink(petname: Petname("ben")!).toPublicMemoAddress(),
                    pfp: "pfp-dog",
                    bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle.",
                    category: .human
                ),
                isFollowingUser: false
            )
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    petname: Petname("ben")!,
                    preferredPetname: nil,
                    address: Slashlink(petname: Petname("ben")!).toPublicMemoAddress(),
                    pfp: "pfp-dog",
                    bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle.",
                    category: .geist
                ),
                statistics: UserProfileStatistics(noteCount: 123, backlinkCount: 64, followingCount: 19),
                isFollowingUser: true
            )
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    petname: Petname("ben")!,
                    preferredPetname: nil,
                    address: Slashlink.ourProfile.toLocalMemoAddress(),
                    pfp: "pfp-dog",
                    bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle.",
                    category: .you
                ),
                isFollowingUser: false
            )
        }
    }
}
