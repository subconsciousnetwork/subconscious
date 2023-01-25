//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//
import SwiftUI
import ObservableStore

struct NotebookNavigationView: View {
    @ObservedObject var store: Store<NotebookModel>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                EntryListView(
                    entries: store.state.recent,
                    onEntryPress: { entry in
                        store.send(
                            .loadAndPresentDetail(
                                link: entry.link,
                                fallback: entry.linkableTitle,
                                autofocus: false
                            )
                        )
                    },
                    onEntryDelete: { slug in
                        store.send(.confirmDelete(slug))
                    },
                    onRefresh: {
                        store.send(.listRecent)
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
                            store.send(.stageDeleteEntry(slug))
                        }
                    ) {
                        Text("Delete Immediately")
                    }
                }
            }
            .navigationDestination(
                isPresented: Binding(
                    store: store,
                    get: \.detail.isPresented,
                    tag: NotebookAction.presentDetail
                ),
                destination: {
                    DetailView(
                        store: ViewStore(
                            store: store,
                            cursor: NotebookDetailCursor.self
                        )
                    )
                }
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    HStack {
                        Text("Notes").bold()
                        CountChip(count: store.state.entryCount)
                    }
                    .frame(minWidth: 200, maxWidth: .infinity)
                }
            }
        }
    }
}
