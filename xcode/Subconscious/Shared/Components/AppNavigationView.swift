//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct AppNavigationView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Divider()
                EntryListView(
                    entries: store.state.recent,
                    onEntryPress: { entry in
                        store.send(
                            action: .requestDetail(
                                slug: entry.slug,
                                fallback: entry.title
                            )
                        )
                    },
                    onEntryDelete: { slug in
                        store.send(
                            action: .confirmDelete(slug)
                        )
                    }
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
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
                            isLoading: store.state.isDetailLoading,
                            backlinks: store.state.backlinks,
                            linkSuggestions: store.state.linkSuggestions,
                            focus: store.binding(
                                get: \.focus,
                                tag: AppAction.setFocus
                            ),
                            editorDom: store.binding(
                                get: \.editorDom,
                                tag: AppAction.modifyEditorDom
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
                                store.send(action: .selectDoneEditing)
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
                            onSelectBacklink: { entryLink in
                                store.send(
                                    action: .requestDetail(
                                        slug: entryLink.slug,
                                        fallback: entryLink.title
                                    )
                                )
                            },
                            onSelectLink: { suggestion in
                                store.send(
                                    action: .selectLinkSuggestion(suggestion)
                                )
                            },
                            onRename: { slug in
                                store.send(action: .showRenameSheet(slug))
                            },
                            onDelete: { slug in
                                store.send(action: .confirmDelete(slug))
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
                    HStack {
                        Text("Ideas").font(Font(UIFont.appTextMedium))
                        CountChip(count: store.state.entryCount)
                    }
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
                    tag: AppAction.setFocus
                ),
                onCancel: {
                    store.send(action: .hideRenameSheet)
                },
                onSelect: { curr, suggestion in
                    store.send(action: .renameEntry(from: curr, to: suggestion))
                }
            )
        }
    }
}
