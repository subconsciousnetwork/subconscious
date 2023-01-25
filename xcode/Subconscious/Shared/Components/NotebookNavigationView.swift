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
        NavigationStack(
            path: Binding(
                store: store,
                get: \.details,
                tag: NotebookAction.setDetails
            )
        ) {
            VStack(spacing: 0) {
                EntryListView(
                    entries: store.state.recent,
                    onEntryPress: { entry in
                        store.send(
                            .pushDetail(
                                slug: entry.slug,
                                title: entry.link.title,
                                fallback: entry.link.title,
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
            .navigationDestination(for: DetailDescription.self) { desc in
                DetailView(
                    slug: desc.slug,
                    title: desc.title,
                    fallback: desc.fallback,
                    onRequestDetail: { slug, title, fallback in
                        store.send(
                            NotebookAction.pushDetail(
                                slug: slug,
                                title: title,
                                fallback: fallback,
                                autofocus: false
                            )
                        )
                    }
                )
            }
            .navigationTitle("Notes")
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
