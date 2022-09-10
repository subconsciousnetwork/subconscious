//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct AppNavigationView: View {
    var store: ViewStore<NotebookModel, NotebookAction>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                    isPresented: Binding(
                        store: store,
                        get: \.isConfirmDeleteShowing,
                        tag: NotebookAction.setConfirmDeleteShowing
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
                    isActive: Binding(
                        store: store,
                        get: \.isDetailShowing,
                        tag: NotebookAction.showDetail
                    ),
                    destination: {
                        DetailView(
                            store: ViewStore(
                                store: store,
                                cursor: NotebookDetailCursor.self
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
                        Text("Notes").font(Font(UIFont.appTextMedium))
                        CountChip(count: store.state.entryCount)
                    }
                    .frame(minWidth: 200, maxWidth: .infinity)
                }
            }
        }
    }
}
