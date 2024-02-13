//
//  EntryListView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import SwiftUI

enum EntryNotification {
    case tapped(EntryStub)
    case like(Slashlink)
    case unlike(Slashlink)
    case delete(Slashlink)
    case linkTapped(EntryLink)
    case quote(Slashlink)
}

/// List view for entries
struct EntryListView: View {
    var entries: [EntryStub]?
    var likes: [Slashlink]?
    var onRefresh: () -> Void
    
    var notify: (EntryNotification) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    static let resetScrollTargetId: Int = 0
    
    private func liked(_ entry: EntryStub) -> Bool {
        likes?.contains(
            where: {
                like in like == entry.address
            })
            ?? false
    }

    var body: some View {
        if let entries = entries {
            if entries.count > 0 {
                List {
                    // invisible marker to scroll back to
                    EmptyView().id(Self.resetScrollTargetId)
                    
                    ForEach(entries.indices, id: \.self) { idx in
                        let entry = entries[idx]
                        
                        Button(
                            action: {
                                notify(.tapped(entry))
                            }
                        ) {
                            EntryRow(
                                entry: entry,
                                highlight: entry.highlightColor,
                                onLink: { link in notify(.linkTapped(link)) }
                            )
                        }
                        .buttonStyle(
                            EntryListRowButtonStyle(
                                color: entry.color
                            )
                        )
                        .modifier(RowViewModifier())
                        .swipeActions(
                            edge: .trailing,
                            allowsFullSwipe: false
                        ) {
                            Button(
                                action: {
                                    notify(.delete(entry.address))
                                }
                            ) {
                                Text("Delete")
                            }
                            .tint(.red)
                        }
                        .contextMenu {
                            ShareLink(item: entry.sharedText)
                            
                            if liked(entry) {
                                Button(
                                    action: {
                                        notify(.unlike(entry.address))
                                    },
                                    label: {
                                        Label(
                                            "Remove from likes",
                                            systemImage: "heart.slash"
                                        )
                                    }
                                )
                            } else {
                                Button(
                                    action: {
                                        notify(.like(entry.address))
                                    },
                                    label: {
                                        Label(
                                            "Add to likes",
                                            systemImage: "heart"
                                        )
                                    }
                                )
                            }
                            
                            Button(
                                action: {
                                    notify(.quote(entry.address))
                                },
                                label: {
                                    Label(
                                        "Quote in new note",
                                        systemImage: "quote.opening"
                                    )
                                }
                            )
                            
                            Divider()
                            
                            Button(
                                role: .destructive,
                                action: {
                                    notify(.delete(entry.address))
                                }
                            ) {
                                Label(
                                    "Delete",
                                    systemImage: "trash"
                                )
                            }
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
            onRefresh: {},
            notify: { _ in }
        )
    }
}
