//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct AppNavigationView: View {
    @ObservedObject var store: Store<AppModel>

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
                    }
                    .onDelete { indexes in
                        store.send(action: .deleteMany(indexes))
                    }
                }
                .listStyle(.plain)
                NavigationLink(
                    isActive: store.binding(
                        get: \.isDetailShowing,
                        tag: AppAction.setDetailShowing
                    ),
                    destination: {
                        DetailView(
                            entryURL: store.state.entryURL,
                            backlinks: store.state.backlinks,
                            focus: store.binding(
                                get: \.focus,
                                tag: AppAction.setFocus,
                                animation: .easeOut(duration: .normal)
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
                                tag: AppAction.setLinkSearchText
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
            .navigationTitle("Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    Text("Ideas").bold()
                }
            }
        }
    }
}
