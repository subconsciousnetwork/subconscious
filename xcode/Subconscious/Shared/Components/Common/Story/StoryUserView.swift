//
//  StoryUserView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

/// Show a user card in a feed format
struct StoryUserView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var story: StoryUser
    var action: (MemoAddress, String) -> Void
    
    var profileAction: (UserProfile, UserProfileAction) -> Void = { _, _ in }

    var body: some View {
        Button(
            action: {
                action(
                    story.user.address,
                    story.user.bio
                )
            }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.unit3) {
                HStack(alignment: .center, spacing: AppTheme.unit2) {
                    ProfilePicSm(pfp: story.user.pfp)
                    PetnameBylineView(petname: story.user.nickname)
                    
                    Spacer()
                    
                    switch (story.isFollowingUser, story.user.category) {
                    case (true, _):
                        Image.from(appIcon: .following)
                            .foregroundColor(.secondary)
                    case (_, .you):
                        Image.from(appIcon: .you(colorScheme))
                            .foregroundColor(.secondary)
                    case (_, _):
                        EmptyView()
                    }
                }
                
                Text(verbatim: story.user.bio)
            }
            .padding()
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .background(Color.background)
    }
}

struct StoryUserView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname("ben.gordon.chris.bob")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!).toPublicMemoAddress(),
                        pfp: .image("pfp-dog"),
                        bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                        category: .human
                    ),
                    isFollowingUser: false
                ),
                action: { link, fallback in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname("ben.gordon.chris.bob")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!).toPublicMemoAddress(),
                        pfp: .image("pfp-dog"),
                        bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                        category: .human
                    ),
                    isFollowingUser: true
                ),
                action: { link, fallback in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname("ben.gordon.chris.bob")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!).toPublicMemoAddress(),
                        pfp: .image("pfp-dog"),
                        bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                        category: .you
                    ),
                    isFollowingUser: false
                ),
                action: { link, fallback in }
            )
        }
    }
}
