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
    
    @Environment (\.colorScheme) var colorScheme

    var body: some View {
        DetailStackView(
            app: app,
            store: store.viewStore(
                get: NotebookDetailStackCursor.get,
                tag: NotebookDetailStackCursor.tag
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
                                    fallback: entry.excerpt.description
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
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                MainToolbar(
                    app: app,
                    profileAction: {
                        store.send(.detailStack(.requestOurProfileDetail))
                    }
                )
                
                ToolbarItemGroup(placement: .principal) {
                    HStack {
                        Text("Notes").bold()
                        CountChip(count: store.state.entryCount)
                    }
                }
            }
            .background(
                colorScheme == .dark ? DeckTheme.darkBg : DeckTheme.lightBg
            )
            .toolbarBackground(
                colorScheme == .dark ? DeckTheme.darkBgStart : DeckTheme.lightBgStart,
                for: .navigationBar
            )
        }
    }
}
