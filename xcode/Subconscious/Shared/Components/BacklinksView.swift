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
                Text("Related Notes")
                    .font(.caption)
                Spacer()
            }
            if backlinks.count > 0 {
                ForEach(backlinks) { entry in
                    TranscludeView(
                        entry: entry,
                        action: {
                            onSelect(EntryLink(entry))
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
                        excerpt: Subtext.truncate(text: "Short", maxBlocks: 2),
                        contentLength: -1,
                        modified: Date.now
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink("/loomings")!,
                        excerpt: Subtext.truncate(
                            text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi.",
                            maxBlocks: 2
                        ),
                        contentLength: -1,
                        modified: Date.now
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink(slug: Slug(formatting: "The Lee Shore")!),
                        excerpt: Subtext.truncate(
                            text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi.",
                            maxBlocks: 2
                        ),
                        contentLength: -1,
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
