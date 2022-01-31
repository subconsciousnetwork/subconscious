//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct AppNavigationView: View {
    @ObservedObject var store: SubconsciousStore

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List(store.state.recent) { entry in
                    Button(
                        action: {
                            store.send(
                                action: .requestDetail(
                                    slug: entry.slug,
                                    fallback: entry.title
                                )
                            )
                        }
                    ) {
                        EntryRow(entry: entry)
                            .padding(.vertical, AppTheme.unit2)
                    }
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: false
                    ) {
                        Button(
                            role: .destructive,
                            action: {
                                store.send(
                                    action: .confirmDelete(entry.slug)
                                )
                            }
                        ) {
                            Text("Delete")
                        }
                    }
                }
                .listStyle(.plain)
                .confirmationDialog(
                    "Are you sure?",
                    isPresented: store.binding(
                        get: \.isConfirmDeleteShowing,
                        tag: AppAction.setConfirmDeleteShowing
                    ),
                    presenting: store.state.entryToDelete
                ) { slug in
                    Button(
                        role: .destructive,
                        action: {
                            withAnimation {
                                store.send(
                                    action: .deleteEntry(slug)
                                )
                            }
                        }
                    ) {
                        Text("Delete Immediately")
                    }
                }
                NavigationLink(
                    isActive: store.binding(
                        get: \.isDetailShowing,
                        tag: AppAction.showDetail
                    ),
                    destination: {
                        DetailView(
                            slug: store.state.slug,
                            backlinks: store.state.backlinks,
                            linkSuggestions: store.state.linkSuggestions,
                            focus: store.binding(
                                get: \.focus,
                                tag: AppAction.setFocus,
                                animation: .easeOut(duration: Duration.normal)
                            ),
                            editorAttributedText: store.binding(
                                get: \.editorAttributedText,
                                tag: AppAction.setEditorAttributedText
                            ),
                            editorSelection: store.binding(
                                get: \.editorSelection,
                                tag: AppAction.setEditorSelection
                            ),
                            isLinkSheetPresented: store.binding(
                                get: \.isLinkSheetPresented,
                                tag: AppAction.setLinkSheetPresented
                            ),
                            linkSearchText: store.binding(
                                get: \.linkSearchText,
                                tag: AppAction.setLinkSearch
                            ),
                            onDone: {
                                store.send(action: .save)
                            },
                            onEditorLink: { url, _, range, _ in
                                store.send(
                                    action: .openEditorURL(
                                        url: url,
                                        range: range
                                    )
                                )
                                return false
                            },
                            onCommitSearch: { query in
                                store.send(
                                    action: .submitSearch(
                                        slug: query.toSlug(),
                                        query: query
                                    )
                                )
                            },
                            onCommitLinkSearch: { query in
                                store.send(
                                    action: .commitLinkSearch(query)
                                )
                            },
                            onRename: { slug in
                                store.send(action: .showRenameSheet(slug))
                            }
                        )
                    },
                    label: {
                        EmptyView()
                    }
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    Text("Ideas").bold()
                }
            }
        }
        .sheet(
            isPresented: store.binding(
                get: \.isRenameSheetShowing,
                tag: { _ in AppAction.hideRenameSheet }
            ),
            onDismiss: {
                store.send(action: .hideRenameSheet)
            }
        ) {
            RenameSearchView(
                slug: store.state.slug,
                suggestions: store.state.renameSuggestions,
                text: store.binding(
                    get: \.renameSlugField,
                    tag: AppAction.setRenameSlugField
                ),
                focus: store.binding(
                    get: \.focus,
                    tag: AppAction.setFocus,
                    animation: .easeOut(duration: Duration.normal)
                ),
                onCancel: {
                    store.send(action: .hideRenameSheet)
                },
                onCommit: { curr, next in
                    store.send(action: .renameEntry(from: curr, to: next))
                }
            )
        }
    }
}
