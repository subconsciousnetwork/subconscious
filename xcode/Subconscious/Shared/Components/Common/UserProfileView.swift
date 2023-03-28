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

struct TabButtonView<Label: View>: View {
    var action: () -> Void
    let label: Label
    var selected: Bool

    init(@ViewBuilder label: () -> Label) {
        self.label = label()
        self.selected = false
        self.action = {}
    }
    
    init(@ViewBuilder label: () -> Label, action: @escaping () -> Void, selected: Bool) {
        self.label = label()
        self.action = action
        self.selected = selected
    }
    
    var body: some View {
        Button(
            action: action,
            label: {
                label
                    .font(.callout)
                    .bold(selected)
            }
        )
        .foregroundColor(selected ? Color.accentColor : Color.secondary )
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct TabViewItem {
    var label: String
    var action: () -> Void
}

struct TabHeaderView: View {
    var items: [TabViewItem]
    var tabChanged: (Int, TabViewItem) -> Void
    var selectedIndex: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    TabButtonView(label: { Text(item.label) }, action: { withAnimation { tabChanged(index, item) } }, selected: index == selectedIndex)
                }
            }
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * (1.0 / CGFloat(items.count)), height: geometry.size.height)
                    .offset(x: geometry.size.width * (1.0 / CGFloat(items.count)) * CGFloat(selectedIndex), y: 0)
                    .animation(.easeInOut(duration: Duration.fast), value: selectedIndex)
            }.frame(height: 2)
        }
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .fill(Color.separator)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct ThreeColumnView: View {
    var user: User
    let focusedColumn: Int

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        VStack {
                            Spacer(minLength: AppTheme.padding)
                            //TODO: note card component
                            ForEach(user.recentArticles, id: \.id) { article in
                                Button(
                                    action: {},
                                    label: {
                                        Transclude2View(address: Slashlink(article.slug)!.toPublicMemoAddress(), excerpt: article.title, action: {})
                                    }
                                )
                            }
                            Button(action: {}, label: { Text("More...") })
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: AppTheme.padding, bottom: 0, trailing: AppTheme.padding))
                    .frame(width: geometry.size.width)
                    
                    ScrollView {
                        VStack {
                            Spacer(minLength: AppTheme.padding)
                            //TODO: note card component
                            ForEach(user.recentArticles, id: \.id) { article in
                                Button(
                                    action: {},
                                    label: {
                                        Transclude2View(address: Slashlink(article.slug)!.toPublicMemoAddress(), excerpt: article.title, action: {})
                                    }
                                )
                            }
                            Button(action: {}, label: { Text("More...") })
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: AppTheme.padding, bottom: 0, trailing: AppTheme.padding))
                    .frame(width: geometry.size.width)
                    
                    ScrollView {
                        VStack {
                            Spacer(minLength: AppTheme.padding)
                            
                            //TODO: user card component
                            ForEach(0..<30) {_ in
                                Button(action: {}, label: { AddressBookEntryView(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did("did:key:123")!) })
                            }
                            
                            Button(action: {}, label: { Text("View All") })
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: AppTheme.padding, bottom: 0, trailing: AppTheme.padding))
                    .frame(width: geometry.size.width)
                }
                .offset(x: -CGFloat(focusedColumn) * geometry.size.width)
            }
        }
    }
}

struct UserProfileView: View {
    let user: User
    @State var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack {
                    HStack(alignment: .top, spacing: AppTheme.unit3) {
                        
                        AsyncImage(url: URL(string: user.profilePicture), content: { image in
                            ProfilePic(image: image)
                        }, placeholder: {
                            ProgressView()
                        })
                        VStack(alignment: .leading, spacing: AppTheme.unit) {
                            PetnameBylineView(rawString: user.petname)
                            Text(verbatim: user.bio)
                            
                            HStack(spacing: AppTheme.unit2) {
                                HStack(spacing: AppTheme.unit) {
                                    Text("\(user.notes)").bold()
                                    Text("Notes").foregroundColor(.secondary)
                                }
                                HStack(spacing: AppTheme.unit) {
                                    Text("\(user.backlinks)").bold()
                                    Text("Backlinks").foregroundColor(.secondary)
                                }
                                HStack(spacing: AppTheme.unit) {
                                    Text("\(user.following)").bold()
                                    Text("Following").foregroundColor(.secondary)
                                }
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
                        selectedIndex: selectedTab
                    )
                        
                }
                
                ThreeColumnView(user: user, focusedColumn: selectedTab)
            }
        }
        .navigationTitle(user.petname)
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
        UserProfileView(user: User(id: UUID(),
                                   notes: 123,
                                   backlinks: 64,
                                   following: 19,
                                   petname: "john-doe",
                                   bio: "SwiftUI developer and tech enthusiast.",
                                   profilePicture: "https://api.dicebear.com/6.x/shapes/png?seed=john-doe",
                                   recentArticles: [
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
                                   ]))
    }
}
