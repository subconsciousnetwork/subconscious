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
                                fallback: entry.linkableTitle,
                                autofocus: false
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
                            store: store.viewStore(
                                get: AppModel.getDetail,
                                tag: AppAction.tagDetail
                            ),
                            linkSuggestions: store.state.linkSuggestions,
                            isLinkSheetPresented: store.binding(
                                get: \.isLinkSheetPresented,
                                tag: AppAction.setLinkSheetPresented
                            ),
                            linkSearchText: store.binding(
                                get: \.linkSearchText,
                                tag: AppAction.setLinkSearch
                            ),
                            onEditorLink: { url, _, range, _ in
                                store.send(
                                    .openEditorURL(
                                        url: url,
                                        range: range
                                    )
                                )
                                return false
                            },
                            keyboardToolbar: DetailKeyboardToolbarView(
                                isSheetPresented: store.binding(
                                    get: \.isLinkSheetPresented,
                                    tag: AppAction.setLinkSheetPresented
                                ),
                                selectedEntryLinkMarkup:
                                    store.state.editor.selectedEntryLinkMarkup,
                                suggestions: store.state.linkSuggestions,
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
                                onDoneEditing: {
                                    store.send(.selectDoneEditing)
                                }
                            )
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
