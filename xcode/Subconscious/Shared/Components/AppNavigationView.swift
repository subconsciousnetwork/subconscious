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
                            .requestDetail(
                                slug: entry.slug,
                                fallback: entry.title
                            )
                        )
                    },
                    onEntryDelete: { slug in
                        store.send(.confirmDelete(slug))
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
                            store.send(.deleteEntry(slug))
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
                            selectedEntryLinkMarkup:
                                store.state.editorSelectedEntryLinkMarkup,
                            focus: store.binding(
                                get: \.focus,
                                tag: { focus in
                                    AppAction.setFocus(
                                        focus: focus,
                                        field: .editor
                                    )
                                }
                            ),
                            editorText: store.binding(
                                get: \.editorText,
                                tag: AppAction.modifyEditor
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
                                store.send(.selectDoneEditing)
                            },
                            onEditorLink: { url, _, range, _ in
                                store.send(
                                    .openEditorURL(
                                        url: url,
                                        range: range
                                    )
                                )
                                return false
                            },
                            onSelectBacklink: { entryLink in
                                store.send(
                                    .requestDetail(
                                        slug: entryLink.slug,
                                        fallback: entryLink.title
                                    )
                                )
                            },
                            onSelectLinkCompletion: { link in
                                store.send(.selectLinkCompletion(link))
                            },
                            onInsertWikilink: {
                                store.send(.insertEditorWikilinkAtSelection)
                            },
                            onInsertBold: {
                                store.send(.insertEditorBoldAtSelection)
                            },
                            onInsertItalic: {
                                store.send(.insertEditorItalicAtSelection)
                            },
                            onInsertCode: {
                                store.send(.insertEditorCodeAtSelection)
                            },
                            onRename: { slug in
                                store.send(.showRenameSheet(slug))
                            },
                            onDelete: { slug in
                                store.send(.confirmDelete(slug))
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
                    .frame(minWidth: 200, maxWidth: .infinity)
                }
            }
        }
    }
}
