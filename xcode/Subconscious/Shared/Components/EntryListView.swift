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
    var onEntryDelete: (Slug) -> Void

    var body: some View {
        if let entries = entries {
            if entries.count > 0 {
                List(entries) { entry in
                    Button(
                        action: {
                            onEntryPress(entry)
                        }
                    ) {
                        Label(
                            title: {
                                EntryRow(entry: entry)
                            },
                            icon: {
                                Image(systemName: "doc")
                            }
                        )
                    }
                    .modifier(RowViewModifier())
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: false
                    ) {
                        Button(
                            role: .destructive,
                            action: {
                                onEntryDelete(entry.slug)
                            }
                        ) {
                            Text("Delete")
                        }
                    }
                }
                .animation(.easeOutCubic(), value: entries)
                .transition(.opacity)
                .listStyle(.plain)
            } else {
                VStack(spacing: AppTheme.unit * 6) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                    Text("Your Subconscious is empty")
                        .font(Font(UIFont.appText))
                    VStack(spacing: AppTheme.unit) {
                        Text(
                            "If your mind is empty, it is always ready for anything, it is open to everything. In the beginner's mind there are many possibilities, but in the expert's mind there are few."
                        )
                        .italic()
                        Text(
                            "Shunryū Suzuki"
                        )
                    }
                    .frame(maxWidth: 280)
                    .font(Font(UIFont.appCaption))
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.secondaryText)
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
            onEntryDelete: { slug in }
        )
    }
}
