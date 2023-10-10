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
    var onNavigate: () -> Void
    
    var profileAction: (UserProfile, UserProfileAction) -> Void = { _, _ in }
    var onRefreshUser: () -> Void = {}
    
    var body: some View {
        switch (story.user) {
        case let .unknown(address, entry):
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: AppTheme.unit2) {
                    Group {
                        ProfilePic(pfp: .generated(entry.did), size: .medium)
                        PetnameView(name: .petname(Slashlink(petname: entry.petname), entry.name), aliases: [])
                        
                        Spacer()
                        
                        switch entry.status {
                        case .unresolved:
                            Image(systemName: "person.fill.questionmark")
                                .foregroundColor(.secondary)
                        case .pending:
                            PendingSyncBadge()
                                .foregroundColor(.secondary)
                        case .resolved:
                            EmptyView()
                        }
                    }
                    .disabled(!entry.status.isReady)
                    
                    Menu(
                        content: {
                            Button(
                                action: {
//                                    profileAction(user, .requestFollow)
                                },
                                label: {
                                    Label(
                                        title: { Text("Follow") },
                                        icon: { Image(systemName: "person.badge.plus") }
                                    )
                                }
                            )
                        },
                        label: {
                            EllipsisLabelView()
                        }
                    )
                }
                .padding(AppTheme.tightPadding)
                .frame(height: AppTheme.unit * 13)
            }
            .contentShape(.interaction, RectangleCroppedTopRightCorner())
            .onTapGesture {
                switch (entry.status) {
                case (.unresolved):
                    onRefreshUser()
                case _:
                    onNavigate()
                }
            }
            .background(.background)
        case let .known(user, entry):
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: AppTheme.unit2) {
                    Group {
                        ProfilePic(pfp: .generated(entry.did), size: .medium)
                        
                        if let name = user.toNameVariant() {
                            PetnameView(name: name, aliases: user.aliases)
                        }
                        
                        Spacer()
                        
                        switch entry.status {
                        case .unresolved:
                            Image(systemName: "person.fill.questionmark")
                                .foregroundColor(.secondary)
                        case .pending:
                            PendingSyncBadge()
                                .foregroundColor(.secondary)
                        case .resolved:
                            switch (user.ourFollowStatus, user.category) {
                            case (.following(_), _):
                                Image.from(appIcon: .following)
                                    .foregroundColor(.secondary)
                            case (_, .ourself):
                                Image.from(appIcon: .you(colorScheme))
                                    .foregroundColor(.secondary)
                            case (_, _):
                                EmptyView()
                            }
                        }
                    }
                    .disabled(!entry.status.isReady)
                    
                    Menu(
                        content: {
                            if user.isFollowedByUs {
                                Button(
                                    action: {
                                        profileAction(user, .requestUnfollow)
                                    },
                                    label: {
                                        Label(
                                            title: { Text("Unfollow") },
                                            icon: { Image(systemName: "person.fill.xmark") }
                                        )
                                    }
                                )
                                Button(
                                    action: {
                                        profileAction(user, .requestRename)
                                    },
                                    label: {
                                        Label(
                                            title: { Text("Rename") },
                                            icon: { Image(systemName: "pencil") }
                                        )
                                    }
                                )
                            } else {
                                Button(
                                    action: {
                                        profileAction(user, .requestFollow)
                                    },
                                    label: {
                                        Label(
                                            title: { Text("Follow") },
                                            icon: { Image(systemName: "person.badge.plus") }
                                        )
                                    }
                                )
                            }
                        },
                        label: {
                            EllipsisLabelView()
                        }
                    ).disabled(user.category == .ourself)
                }
                .padding(AppTheme.tightPadding)
                .frame(height: AppTheme.unit * 13)
                
                if let bio = user.bio,
                   bio.hasVisibleContent {
                    Text(verbatim: bio.text)
                        .padding(AppTheme.tightPadding)
                }
            }
            .contentShape(.interaction, RectangleCroppedTopRightCorner())
            .onTapGesture {
                switch (user.ourFollowStatus, entry.status) {
                case (.following(_), .unresolved):
                    onRefreshUser()
                default:
                    onNavigate()
                }
            }
            .background(.background)
        }
    }
}

struct StoryUserView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            StoryUserView(
                story: StoryUser(
                    user: .known(
                        UserProfile(
                            did: Did("did:key:123")!,
                            nickname: Petname.Name("ben")!,
                            address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                            pfp: .image("pfp-dog"),
                            bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                            category: .human,
                            ourFollowStatus: .notFollowing,
                            aliases: []
                        ),
                        AddressBookEntry(
                            petname: Petname("ben")!,
                            did: Did("did:key:123")!,
                            status: .resolved("ok"),
                            version: "ok"
                        )
                    )
                ),
                onNavigate: { }
            )
            StoryUserView(
                story: StoryUser(
                    user: .known(
                        UserProfile(
                            did: Did("did:key:123")!,
                            nickname: Petname.Name("ben")!,
                            address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                            pfp: .image("pfp-dog"),
                            bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                            category: .human,
                            ourFollowStatus: .following(Petname.Name("lol")!),
                            aliases: []
                        ),
                        AddressBookEntry(
                            petname: Petname("ben")!,
                            did: Did("did:key:123")!,
                            status: .resolved("ok"),
                            version: "ok"
                        )
                    )
                ),
                onNavigate: { }
            )
            StoryUserView(
                story: StoryUser(
                    user: .known(
                        UserProfile(
                            did: Did("did:key:123")!,
                            nickname: Petname.Name("ben")!,
                            address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                            pfp: .image("pfp-dog"),
                            bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                            category: .ourself,
                            ourFollowStatus: .notFollowing,
                            aliases: []
                        ),
                        AddressBookEntry(
                            petname: Petname("ben")!,
                            did: Did("did:key:123")!,
                            status: .resolved("ok"),
                            version: "ok"
                        )
                    )
                ),
                onNavigate: { }
            )
            StoryUserView(
                story: StoryUser(
                    user: .known(
                        UserProfile(
                            did: Did("did:key:123")!,
                            nickname: Petname.Name("ben")!,
                            address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                            pfp: .image("pfp-dog"),
                            bio: UserProfileBio.empty,
                            category: .ourself,
                            ourFollowStatus: .notFollowing,
                            aliases: []
                        ),
                        AddressBookEntry(
                            petname: Petname("ben")!,
                            did: Did("did:key:123")!,
                            status: .resolved("ok"),
                            version: "ok"
                        )
                    )
                ),
                onNavigate: { }
            )
            Spacer()
        }
        .background(.secondary)
        .frame(maxHeight: .infinity)
    }
}
