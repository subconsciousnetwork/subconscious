//
//  BacklinksView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct BacklinksView: View {
    var backlinks: [EntryStub]
    var onSelect: (EntryLink) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            HStack {
                Text("Backlinks")
                    .font(.caption)
                Spacer()
            }
            if backlinks.count > 0 {
                ForEach(backlinks) { entry in
                    TranscludeView(
                        author: entry.author,
                        address: entry.address,
                        excerpt: entry.excerpt,
                        action: {
                            onSelect(EntryLink(entry))
                        }
                    )
                }
            } else {
                TitleGroupView(
                    title: Text("No backlinks yet")
                        .foregroundColor(Color.secondary),
                    subtitle: Text(
                        "Links to this note will appear here"
                    )
                )
            }
            
            FabSpacerView()
        }
        .padding(.horizontal, AppTheme.unit4)
        .padding(.vertical, AppTheme.unit2)
    }
}

struct BacklinksView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BacklinksView(
                backlinks: [
                    EntryStub(
                        address: Slashlink("@handle/short")!,
                        excerpt: "Short",
                        modified: Date.now,
                        author: UserProfile.dummyData()
                    ),
                    EntryStub(
                        address: Slashlink("/loomings")!,
                        excerpt: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi.",
                        modified: Date.now,
                        author: UserProfile.dummyData()
                    ),
                    EntryStub(
                        address: Slashlink(slug: Slug(formatting: "The Lee Shore")!),
                        excerpt: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi.",
                        modified: Date.now,
                        author: UserProfile.dummyData()
                    )
                ],
                onSelect: { title in }
            )
            BacklinksView(
                backlinks: [],
                onSelect: { title in }
            )
        }
    }
}
