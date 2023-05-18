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
    var hideActionButton: Bool = false
    
    var onTapStatistics: () -> Void = { }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit3) {
            HStack(alignment: .center, spacing: AppTheme.unit3) {
                ProfilePic(pfp: user.pfp, size: .large)
            
                PetnameView(
                    address: user.address,
                    petname: user.nickname?.toPetname() ?? user.address.petname ?? Petname.unknown
                )
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                
                Spacer()
                
                if !hideActionButton {
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
            }
            
            if let statistics = statistics {
                Button(
                    action: {
                        onTapStatistics()
                    },
                    label: {
                        HStack(spacing: AppTheme.unit2) {
                            ProfileStatisticView(label: "Notes", count: statistics.noteCount)
                            // TODO: put this back when we have backlink count
                            // ProfileStatisticView(label: "Backlinks", count: statistics.backlinkCount)
                            ProfileStatisticView(label: "Following", count: statistics.followingCount)
                        }
                        .font(.caption)
                        .foregroundColor(.primary)
                    }
                )
            }
            
            if user.bio.hasVisibleContent {
                Text(verbatim: user.bio.text)
            }
        }
    }
}

struct BylineLgView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    nickname: PetnamePart("ben")!,
                    address: Slashlink(petname: Petname("ben")!),
                    pfp: .image("pfp-dog"),
                    bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle."),
                    category: .human,
                    resolutionStatus: .resolved("abc")
                ),
                isFollowingUser: false
            )
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    nickname: PetnamePart("ben")!,
                    address: Slashlink(petname: Petname("ben")!),
                    pfp: .image("pfp-dog"),
                    bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle."),
                    category: .geist,
                    resolutionStatus: .resolved(Cid("ok"))
                ),
                statistics: UserProfileStatistics(noteCount: 123, backlinkCount: 64, followingCount: 19),
                isFollowingUser: true
            )
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    nickname: PetnamePart("ben")!,
                    address: Slashlink.ourProfile,
                    pfp: .image("pfp-dog"),
                    bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle."),
                    category: .you,
                    resolutionStatus: .resolved(Cid("ok"))
                ),
                isFollowingUser: false
            )
        }
    }
}
