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

enum ProfileHeaderButtonVariant {
    case primary
    case secondary
}

struct UserProfileHeaderView: View {
    var user: UserProfile
    var statistics: UserProfileStatistics?
    
    var action: (UserProfileAction) -> Void = { _ in }
    var hideActionButton: Bool = false
    
    var onTapStatistics: () -> Void = { }
    
    var profileAction: UserProfileAction {
        switch (user.category, user.ourFollowStatus) {
        case (.ourself, _):
            return .editOwnProfile
        case (_, .following(_)):
            return .requestUnfollow
        case (_, .notFollowing):
            return .requestFollow
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit3) {
            HStack(alignment: .center, spacing: AppTheme.unit3) {
                ProfilePic(pfp: user.pfp, size: .large)
                
                if let name = user.toNameVariant() {
                    PetnameView(
                        name: name,
                        showMaybePrefix: true
                    )
               }
                
            }
            
            Button(
                action: {
                    onTapStatistics()
                },
                label: {
                    HStack(spacing: AppTheme.unit2) {
                        ProfileStatisticView(label: "Notes", count: statistics?.noteCount)
                        // TODO: put this back when we have backlink count
                        // ProfileStatisticView(label: "Backlinks", count: statistics.backlinkCount)
                        ProfileStatisticView(label: "Following", count: statistics?.followingCount)
                    }
                    .font(.caption)
                    .foregroundColor(.primary)
                }
            )
            
            if let bio = user.bio,
               bio.hasVisibleContent {
                Text(verbatim: bio.text)
            }
            
            
            if !hideActionButton {
                Button(
                    action: {
                        action(profileAction)
                    },
                    label: {
                        switch (user.category, user.ourFollowStatus) {
                        case (.ourself, _):
                            Label("Edit Profile", systemImage: AppIcon.edit.systemName)
                        case (_, .following(_)):
                            Label("Following", systemImage: AppIcon.following.systemName)
                        case (_, .notFollowing):
                            Text("Follow")
                        }
                    }
                )
                .buttonStyle(
                    // Button has primary style when we can follow
                    ProfileHeaderButtonStyle(
                        variant: profileAction == .requestFollow
                            ? .primary
                            : .secondary
                    )
                )
            }
        }
    }
}

struct BylineLgView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    nickname: Petname.Name("ben")!,
                    address: Slashlink(petname: Petname("ben")!),
                    pfp: .image("pfp-dog"),
                    bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle."),
                    category: .human,
                    resolutionStatus: .resolved("abc"),
                    ourFollowStatus: .notFollowing
                )
            )
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    nickname: Petname.Name("ben")!,
                    address: Slashlink(petname: Petname("ben")!),
                    pfp: .image("pfp-dog"),
                    bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle."),
                    category: .geist,
                    resolutionStatus: .resolved(Cid("ok")),
                    ourFollowStatus: .following(Petname.Name("ben")!)
                ),
                statistics: UserProfileStatistics(noteCount: 123, backlinkCount: 64, followingCount: 19)
            )
            UserProfileHeaderView(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    nickname: Petname.Name("ben")!,
                    address: Slashlink.ourProfile,
                    pfp: .image("pfp-dog"),
                    bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle."),
                    category: .ourself,
                    resolutionStatus: .resolved(Cid("ok")),
                    ourFollowStatus: .notFollowing
                )
            )
        }
        .padding()
    }
}
