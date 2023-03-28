//
//  UserProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2023.
//

import Foundation
import SwiftUI

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
    
    let onNavigateToNote: (MemoAddress) -> Void
    let onNavigateToUser: (MemoAddress) -> Void
    
    @State var selectedTab = 0
    
    func makeColumns() -> [TabbedColumnItem] {
        return [
            TabbedColumnItem(
                label: "Recent",
                view: Group {
                    //TODO: note card component
                    ForEach(articles, id: \.id) { article in
                        Button(
                            action: {},
                            label: {
                                let address = Slashlink(article.slug)!.toPublicMemoAddress()
                                Transclude2View(
                                    address: address,
                                    excerpt: article.title,
                                    action: {
                                        onNavigateToNote(address)
                                    }
                                )
                            }
                        )
                    }
                    Button(action: {}, label: { Text("More...") })
                }
            ),
            TabbedColumnItem(
                label: "Top",
                view: Group {
                    //TODO: note card component
                    ForEach(articles, id: \.id) { article in
                        Button(
                            action: {},
                            label: {
                                let address = Slashlink(article.slug)!.toPublicMemoAddress()
                                Transclude2View(
                                    address: address,
                                    excerpt: article.title,
                                    action: {
                                        onNavigateToNote(address)
                                    }
                                )
                            }
                        )
                    }
                    Button(action: {}, label: { Text("More...") })
                }
            ),
            TabbedColumnItem(
                label: "Following",
                view: Group {
                    //TODO: user card component
                    ForEach(0..<30) {_ in
                        Button(
                            action: {
                                onNavigateToUser(Slashlink("@ben/_profile_")!.toPublicMemoAddress())
                                
                            },
                            label: {
                                AddressBookEntryView(
                                    pfp: Image("pfp-dog"),
                                    petname: Petname("ben")!,
                                    did: Did("did:key:123")!
                                )
                            }
                        )
                    }
                    
                    Button(action: {}, label: { Text("View All") })
                }
            )
        ]
    }

    var body: some View {
        // Break this up so SwiftUI can actually typecheck
        let columns = self.makeColumns()
        
        VStack(alignment: .leading, spacing: 0) {
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
            
            TabbedColumnView(
                columns: columns,
                selectedColumnIndex: selectedTab,
                changeColumn: { index in
                    selectedTab = index
                }
            )
        }
        .navigationTitle(user.petname.verbatim)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            DetailToolbarContent(
                address: Slashlink(petname: user.petname).toPublicMemoAddress(),
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
            ],
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") }
        )
    }
}
