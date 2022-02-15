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
                Divider()
                if store.state.recent.count > 0 {
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
                                    store.send(
                                        action: .confirmDelete(entry.slug)
                                    )
                                }
                            ) {
                                Text("Delete")
                            }
                        }
                    }
                    .animation(.easeOutCubic(), value: store.state.recent)
                    .transition(.opacity)
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
                            editorDom: store.binding(
                                get: \.editorDom,
                                tag: AppAction.updateEditorDom
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
                                withAnimation(
                                    .easeOutCubic(duration: Duration.fast)
                                ) {
                                    store.send(action: .selectDoneEditing)
                                }
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
                    Text("Ideas")
                        .font(Font(UIFont.appTextMedium))
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
