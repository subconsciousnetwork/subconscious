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
                            EntryRow(entry: entry)
                                .equatable()
                        }
                        .modifier(RowViewModifier())
                        .swipeActions(
                            edge: .trailing,
                            allowsFullSwipe: false
                        ) {
                            Button(
                                role: .destructive,
                                action: {
                                    onEntryDelete(entry.address)
                                }
                            ) {
                                Text("Delete")
                            }
                        }
                    }
                    .background(Color.background)
                    // Add space at the bottom of the list so that FAB
                    // does not cover up swipe actions of last item.
                    Color.clear
                        .frame(
                            height: (
                                AppTheme.fabSize +
                                (AppTheme.unit * 6)
                            )
                        )
                        .listRowSeparator(.hidden)
                }
                .animation(.easeOutCubic(), value: entries)
                .transition(.opacity)
                .refreshable {
                    onRefresh()
                }
                .listStyle(.plain)
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
            entries: [],
            onEntryPress: { entry in },
            onEntryDelete: { slug in },
            onRefresh: {}
        )
    }
}
