//
//  BacklinksView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct BacklinksView: View {
    var backlinks: [EntryStub]
    var onRequestDetail: (EntryLink) -> Void
    var onLink: (_ context: ResolvedAddress, SubSlashlinkLink) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            HStack {
                Text("Related Notes")
                    .font(.caption)
                Spacer()
            }
            if backlinks.count > 0 {
                ForEach(backlinks) { entry in
                    TranscludeView(
                        entry: entry,
                        onRequestDetail: {
                            onRequestDetail(EntryLink(entry))
                        },
                        onLink: { link in
                            onLink(entry.toResolvedAddress(), link)
                        }
                    )
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
                        isTruncated: false,
                        modified: Date.now
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink("/loomings")!,
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        isTruncated: false,
                        modified: Date.now
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink(slug: Slug(formatting: "The Lee Shore")!),
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        isTruncated: false,
                        modified: Date.now
                    ),
                    EntryStub(
                        did: Did.local,
                        address: Slashlink(slug: Slug(formatting: "The whale, the whale")!),
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        isTruncated: false,
                        modified: Date.now
                    )
                ],
                onRequestDetail: { title in },
                onLink: { address, link in }
            )
            BacklinksView(
                backlinks: [],
                onRequestDetail: { title in },
                onLink: { address, link in }
            )
        }
    }
}
