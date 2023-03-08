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
                    Button(
                        action: {
                            onSelect(
                                EntryLink(entry)
                            )
                        },
                        label: {
                            Transclude2View(
                                address: entry.address,
                                excerpt: entry.excerpt
                            )
                        }
                    )
                    .buttonStyle(.plain)
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
                        address: Slashlink("@handle/short")!
                            .toPublicMemoAddress(),
                        excerpt: "Short",
                        modified: Date.now
                    ),
                    EntryStub(
                        address: Slug(formatting: "The Lee Shore")!
                            .toLocalMemoAddress(),
                        excerpt: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi.",
                        modified: Date.now
                    ),
                    EntryStub(
                        address: Slashlink("/loomings")!
                            .toPublicMemoAddress(),
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
