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
                                MemoEditorDetailDescription(
                                    address: entry.address,
                                    fallback: entry.excerpt
                                )
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
                    "Are you sure you want to delete this note?",
                    isPresented: Binding(
                        get: { store.state.isConfirmDeleteShowing },
                        send: store.send,
                        tag: NotebookAction.setConfirmDeleteShowing
                    ),
                    titleVisibility: .visible,
                    presenting: store.state.entryToDelete
                ) { slug in
                    Button(
                        role: .destructive,
                        action: {
                            store.send(.stageDeleteEntry(slug))
                        }
                    ) {
                        Text("Delete")
                    }
                }
            }
            .navigationDestination(
                for: MemoDetailDescription.self
            ) { detail in
                switch detail {
                case .editor(let description):
                    MemoEditorDetailView(
                        description: description,
                        notify: Address.forward(
                            send: store.send,
                            tag: NotebookAction.tag
                        )
                    )
                case .viewer(let description):
                    MemoViewerDetailView(
                        description: description,
                        notify: Address.forward(
                            send: store.send,
                            tag: NotebookAction.tag
                        )
                    )
                case .profile(let description):
                    UserProfileDetailView(
                        description: description,
                        notify: Address.forward(
                            send: store.send,
                            tag: NotebookAction.tag
                        )
                    )
                }
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
                if AppDefaults.standard.isNoosphereEnabled {
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
                if Config.default.userProfile {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(
                            action: {
                                let dummyUser = UserProfile.dummyData()
                                let detail = UserProfileDetailDescription(
                                    user: dummyUser,
                                    spherePath: [dummyUser]
                                )
                                
                                store.send(.pushDetail(.profile(detail)))
                            }
                        ) {
                            Image(systemName: "person")
                        }
                    }
                }
            }
        }
    }
}
