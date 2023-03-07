//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//
import SwiftUI
import ObservableStore

struct NotebookNavigationView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<NotebookModel>

    var body: some View {
        NavigationStack(
            path: Binding(
                get: { store.state.details },
                send: store.send,
                tag: NotebookAction.setDetails
            )
        ) {
            VStack(spacing: 0) {
                EntryListView(
                    entries: store.state.recent,
                    onEntryPress: { entry in
                        store.send(
                            .pushDetail(
                                address: entry.address,
                                title: entry.title,
                                fallback: entry.title,
                                autofocus: false
                            )
                        )
                    },
                    onEntryDelete: { address in
                        store.send(.confirmDelete(address))
                    },
                    onRefresh: {
                        app.send(.syncAll)
                    }
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .confirmationDialog(
                    "Are you sure?",
                    isPresented: Binding(
                        get: { store.state.isConfirmDeleteShowing },
                        send: store.send,
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
            .navigationDestination(for: DetailOuterModel.self) { state in
                DetailView(
                    state: state,
                    send: Address.forward(
                        send: store.send,
                        tag: NotebookAction.tag
                    )
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
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: {
                            app.send(.presentSettingsSheet(true))
                        }
                    ) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: {
                            app.send(.presentAddressBook(true))
                        }
                    ) {
                        Image(systemName: "person.2")
                    }
                }
            }
        }
    }
}
