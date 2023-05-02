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
                VStack(spacing: AppTheme.unit * 6) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                    Text("Your Subconscious is empty")
                    VStack(spacing: AppTheme.unit) {
                        Text(
                            "If your mind is empty, it is always ready for anything, it is open to everything. In the beginner's mind there are many possibilities, but in the expert's mind there are few."
                        )
                        .italic()
                        Text(
                            "Shunryū Suzuki"
                        )
                    }
                    .frame(maxWidth: 240)
                    // Some extra padding to visually center the group.
                    // The icon is large and rather heavy. This offset
                    // helps prevent the illusion of being off-center.
                    .padding(.bottom, AppTheme.unit * 24)
                    .font(.caption)
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.secondary)
                .background(Color.background)
                .transition(.opacity)
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
