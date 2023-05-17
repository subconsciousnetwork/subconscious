//
//  StoryUserView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

/// Adjusts the hit mask of a view to exclude the top-right corner so we can add buttons there
/// without having to deal with firing both tap targets at once.
private struct RectangleCroppedTopRightCorner: Shape {
    static let margin: CGSize = CGSize(
        width: AppTheme.minTouchSize + AppTheme.tightPadding,
        height: AppTheme.minTouchSize + AppTheme.tightPadding
    )
    
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - Self.margin.width, y: rect.minY))
        path.addLine(
            to: CGPoint(
                x: rect.maxX - Self.margin.width,
                y: rect.minY + Self.margin.height
            )
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + Self.margin.height))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

/// Show a user card in a feed format
struct StoryUserView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var story: StoryUser
    var action: (Slashlink, String) -> Void
    
    var profileAction: (UserProfile, UserProfileAction) -> Void = { _, _ in }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: AppTheme.unit2) {
                ProfilePic(pfp: story.user.pfp, size: .medium)
                PetnameView(
                    nickname: story.user.nickname,
                    petname: story.user.address.petname
                )
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                
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
                
                Menu(
                    content: {
                        if story.isFollowingUser {
                            Button(
                                action: {
                                    profileAction(story.user, .requestUnfollow)
                                },
                                label: {
                                    Label(
                                        title: { Text("Unfollow \(story.user.nickname.markup)") },
                                        icon: { Image(systemName: "person.fill.xmark") }
                                    )
                                }
                            )
                        } else {
                            Button(
                                action: {
                                    profileAction(story.user, .requestFollow)
                                },
                                label: {
                                    Label(
                                        title: { Text("Follow \(story.user.nickname.markup)") },
                                        icon: { Image(systemName: "person.badge.plus") }
                                    )
                                }
                            )
                        }
                       
                    },
                    label: {
                        Image(systemName: "ellipsis")
                            .frame(width: AppTheme.minTouchSize, height: AppTheme.minTouchSize)
                            .background(.background)
                            .foregroundColor(.secondary)
                    }
                )
            }
            .padding(AppTheme.tightPadding)
            .frame(height: AppTheme.unit * 13)
            
            if story.user.bio.hasVisibleContent {
                Divider()
                Text(verbatim: story.user.bio.bio)
                    .padding(AppTheme.tightPadding)
            }
        }
        .contentShape(.interaction, RectangleCroppedTopRightCorner())
        .onTapGesture {
            action(
                story.user.address,
                story.user.bio.bio
            )
        }
        .background(.background)
    }
}

struct StoryUserView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .human
                    ),
                    isFollowingUser: false
                ),
                action: { _, _ in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname("ben.gordon.chris.bob")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .human
                    ),
                    isFollowingUser: true
                ),
                action: { _, _ in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname("ben.gordon.chris.bob")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .you
                    ),
                    isFollowingUser: false
                ),
                action: { _, _ in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname("ben.gordon.chris.bob")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio.empty,
                        category: .you
                    ),
                    isFollowingUser: false
                ),
                action: { _, _ in }
            )
            Spacer()
        }
        .background(.secondary)
        .frame(maxHeight: .infinity)
    }
}
