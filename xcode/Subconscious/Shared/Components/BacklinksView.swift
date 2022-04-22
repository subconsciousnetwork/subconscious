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
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Backlinks")
                .font(Font(UIFont.appCaption))
                Spacer()
            }
            .padding(.horizontal, AppTheme.unit4)
            .padding(.vertical, AppTheme.unit2)
            if backlinks.count > 0 {
                ForEach(backlinks) { entry in
                    Divider()
                    Button(
                        action: {
                            onSelect(
                                EntryLink(
                                    slug: entry.slug,
                                    title: entry.title
                                )
                            )
                        },
                        label: {
                            EntryRow(entry: entry)
                        }
                    )
                    .buttonStyle(BacklinkButtonStyle())
                }
            } else {
                Divider()
                TitleGroupView(
                    title: Text("No backlinks yet")
                        .foregroundColor(Color.secondaryText),
                    subtitle: Text(
                        "Links to this note will appear here"
                    )
                )
                .padding(.horizontal, AppTheme.unit4)
                .padding(.vertical, AppTheme.unit3)
            }
        }
    }
}

struct BacklinksView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BacklinksView(
                backlinks: [
                    EntryStub(
                        slug: Slug("floop")!,
                        title: "Floop",
                        excerpt: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi.",
                        modified: Date.now
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
