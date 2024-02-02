//
//  BacklinksView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct BacklinksView: View {
    var backlinks: [EntryStub]
    var onLink: (_ link: EntryLink) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            HStack {
                Text("Related Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if backlinks.count > 0 {
                VStack(spacing: AppTheme.unit2) {
                    ForEach(backlinks, id: \.self) { entry in
                        VStack {
                            TranscludeView(
                                entry: entry,
                                onLink: onLink
                            )
                            .buttonStyle(RelatedNoteButtonStyle(color: entry.color))
                        }
                        .tint(
                            entry.headers.themeColor?.toHighlightColor()
                        )
                    }
                }
            } else {
                TitleGroupView(
                    title: Text("No related notes yet")
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
                        did: Did.dummyData(),
                        address: Slashlink("@handle/short")!,
                        excerpt: Subtext(markup: "Short"),
                        headers: .emptySubtext
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink("/loomings")!,
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        headers: .emptySubtext
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink(slug: Slug(formatting: "The Lee Shore")!),
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        headers: .emptySubtext
                    ),
                    EntryStub(
                        did: Did.local,
                        address: Slashlink(slug: Slug(formatting: "The whale, the whale")!),
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        headers: .emptySubtext
                    )
                ],
                onLink: { link in }
            )
            BacklinksView(
                backlinks: [],
                onLink: { link in }
            )
        }
    }
}
