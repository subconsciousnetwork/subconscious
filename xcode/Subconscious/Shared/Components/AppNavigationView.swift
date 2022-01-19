//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct AppNavigationView: View {
    @ObservedObject var store: Store<AppModel, AppAction>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(store.state.recent) { entry in
                        Button(
                            action: {
                                store.send(
                                    action: .commit(
                                        query: entry.title,
                                        slug: entry.slug
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
                        tag: AppAction.setDetailShowing
                    ),
                    destination: {
                        DetailView(
                            slug: store.state.slug,
                            backlinks: store.state.backlinks,
                            focus: store.binding(
                                get: \.focus,
                                tag: AppAction.setFocus,
                                animation: .easeOut(duration: .normal)
                            ),
                            slugField: store.binding(
                                get: \.slugField,
                                tag: AppAction.setSlugField
                            ),
                            editorAttributedText: store.binding(
                                get: \.editorAttributedText,
                                tag: AppAction.setEditorAttributedText
                            ),
                            editorSelection: store.binding(
                                get: \.editorSelection,
                                tag: AppAction.setEditorSelection
                            ),
                            isRenamePresented: store.binding(
                                get: \.isRenameShowing,
                                tag: AppAction.setRenameShowing
                            ),
                            isLinkSheetPresented: store.binding(
                                get: \.isLinkSheetPresented,
                                tag: AppAction.setLinkSheetPresented
                            ),
                            linkSearchText: store.binding(
                                get: \.linkSearchText,
                                tag: AppAction.setLinkSearch
                            ),
                            linkSuggestions: store.binding(
                                get: \.linkSuggestions,
                                tag: AppAction.setLinkSuggestions
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
                                    action: .commitSearch(query: query)
                                )
                            },
                            onCommitLinkSearch: { query in
                                store.send(
                                    action: .commitLinkSearch(query)
                                )
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
    }
}
