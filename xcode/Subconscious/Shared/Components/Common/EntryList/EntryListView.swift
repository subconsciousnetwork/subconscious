//
//  EntryListView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import SwiftUI

/// List view for entries
struct EntryListView: View {
    var entries: [EntryStub]?
    var onEntryPress: (EntryStub) -> Void
    var onEntryDelete: (Slashlink) -> Void
    var onRefresh: () -> Void
    var onLink: (EntryLink) -> Void
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let entries = entries {
            if entries.count > 0 {
                List {
                    ForEach(entries) { entry in
                        Button(
                            action: {
                                onEntryPress(entry)
                            }
                        ) {
                            EntryRow(
                                entry: entry,
                                highlight: entry.highlightColor(
                                    colorScheme: colorScheme
                                ),
                                onLink: onLink
                            )
                        }
                        .buttonStyle(
                            EntryListRowButtonStyle(
                                color: entry.color(
                                    colorScheme: colorScheme
                                )
                            )
                        )
                        .modifier(RowViewModifier())
                        .swipeActions(
                            edge: .trailing,
                            allowsFullSwipe: false
                        ) {
                            Button(
                                action: {
                                    onEntryDelete(entry.address)
                                }
                            ) {
                                Text("Delete")
                            }
                            .tint(.red)
                        }
                    }
                    
                    FabSpacerView()
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .background(.clear)
                .scrollContentBackground(.hidden)
                .transition(.opacity)
                .refreshable {
                    onRefresh()
                }
            } else {
                EntryListEmptyView(onRefresh: onRefresh)
            }
        } else {
            ProgressScrimView()
        }
    }
}

struct EntryListView_Previews: PreviewProvider {
    static var previews: some View {
        EntryListView(
            entries: [
                EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "did:subconscious:local/anything-that-can-be-derived-should-be-derived"
                    )!,
                    excerpt: Subtext(
                        markup: "Anything that can be derived should be derived. Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply."
                    ),
                    headers: .emptySubtext
                ),
                EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "did:subconscious:local/anything-that-can-be-derived-should-be-derived"
                    )!,
                    excerpt: Subtext(
                        markup: "Anything that can be derived should be derived. Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply."
                    ),
                    headers: .emptySubtext
                )
            ],
            onEntryPress: { entry in },
            onEntryDelete: { slug in },
            onRefresh: {},
            onLink: { _ in }
        )
    }
}
