//
//  StoryPlainView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

/// A story is a single update within the FeedView
struct StoryUserView: View {
    var story: StoryUser
    var action: (MemoAddress, String) -> Void

    var body: some View {
        Button(
            action: {
                action(
                    Slashlink(petname: story.user.petname)
                        .toPublicMemoAddress(),
                    story.user.bio
                )
            }
        ) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: AppTheme.unit4) {
                    UserProfileHeaderView(
                        user: story.user,
                        statistics: story.statistics,
                        isFollowingUser: story.following
                    )
                }
                .padding()
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .background(Color.background)
    }
}

struct StoryUserView_Previews: PreviewProvider {
    static var previews: some View {
        StoryUserView(
            story: StoryUser(
                user: UserProfile(
                    did: Did("did:key:123")!,
                    petname: Petname("ben")!,
                    pfp: "pfp-dog",
                    bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                    category: .human
                ),
                following: false
            ),
            action: { link, fallback in }
        )
    }
}
