//
//  UserProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2023.
//

import Foundation
import SwiftUI

struct User {
    let id: UUID
    let notes: Int
    let backlinks: Int
    let following: Int
    let petname: String
    let bio: String
    let profilePicture: String
    let recentArticles: [Article]
}

struct Article {
    let id: UUID
    let title: String
    let slug: String
    let datePublished: Date
}

struct UserProfileStatistics {
    let noteCount: Int
    let backlinkCount: Int
    let followingCount: Int
}

struct UserProfile {
    let petname: Petname
    let pfp: Image
    let bio: String
    
    let statistics: UserProfileStatistics
}

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
    let articles: [Article]
    @State var selectedTab = 0
    
    func makeColumns() -> [any View] {
        return [
            Group {
                //TODO: note card component
                ForEach(articles, id: \.id) { article in
                    Button(
                        action: {},
                        label: {
                            Transclude2View(address: Slashlink(article.slug)!.toPublicMemoAddress(), excerpt: article.title, action: {})
                        }
                    )
                }
                Button(action: {}, label: { Text("More...") })
            },
            Group {
                //TODO: note card component
                ForEach(articles, id: \.id) { article in
                    Button(
                        action: {},
                        label: {
                            Transclude2View(address: Slashlink(article.slug)!.toPublicMemoAddress(), excerpt: article.title, action: {})
                        }
                    )
                }
                Button(action: {}, label: { Text("More...") })
            },
            Group {
                //TODO: user card component
                ForEach(0..<30) {_ in
                    Button(action: {}, label: { AddressBookEntryView(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did("did:key:123")!) })
                }
                
                Button(action: {}, label: { Text("View All") })
            }
        ]
    }

    var body: some View {
        // Break this up so SwiftUI can actually typecheck
        let columns = self.makeColumns().map({ v in AnyView(v) })
        
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: AppTheme.unit3) {
                        ProfilePic(image: user.pfp)
                        
                        VStack(alignment: .leading, spacing: AppTheme.unit) {
                            PetnameBylineView(petname: user.petname)
                            Text(verbatim: user.bio)
                            
                            HStack(spacing: AppTheme.unit2) {
                                ProfileStatisticView(label: "Notes", count: user.statistics.noteCount)
                                ProfileStatisticView(label: "Backlinks", count: user.statistics.backlinkCount)
                                ProfileStatisticView(label: "Following", count: user.statistics.followingCount)
                            }
                            .padding([.top], AppTheme.unit2)
                            .font(.caption)
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(AppTheme.padding)
                    
                    TabHeaderView(
                        items: [
                            TabViewItem(label: "Recent", action: {}),
                            TabViewItem(label: "Top", action: {}),
                            TabViewItem(label: "Following", action: {}),
                        ],
                        tabChanged: { index, tab in selectedTab = index },
                        focusedTabIndex: selectedTab
                    )
                }
                
                MultiColumnView(
                    focusedColumnIndex: selectedTab,
                    columns: columns
                )
            }
        }
        .navigationTitle(user.petname.verbatim)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            DetailToolbarContent(
                address: Slashlink("@\(user.petname)/profile")!.toPublicMemoAddress(),
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
                pfp: Image("pfp-dog"),
                bio: "Henlo world.",
                statistics: UserProfileStatistics(
                    noteCount: 123,
                    backlinkCount: 64,
                    followingCount: 19
                )
            ),
            articles: [
                Article(id: UUID(), title: "Article 1", slug: "/article-1", datePublished: Date()),
                Article(id: UUID(), title: "Article 2", slug: "/article-2", datePublished: Date().addingTimeInterval(-86400)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
            ]
        )
    }
}
