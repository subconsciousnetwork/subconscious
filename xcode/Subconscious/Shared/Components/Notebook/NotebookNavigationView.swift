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
    
    func notify(_ notification: EntryNotification) -> Void {
        switch notification {
        case let .requestDetail(entry):
            store.send(
                .pushDetail(
                    MemoEditorDetailDescription(
                        address: entry.address,
                        fallback: entry.excerpt.description
                    )
                )
            )
        case let .delete(address):
            store.send(
                .confirmDelete(
                    address
                )
            )
        case let .requestLinkDetail(link):
            store.send(
                .detailStack(
                    .findAndPushLinkDetail(
                        link
                    )
                )
            )
        case let .quote(address):
            store.send(
                .detailStack(
                    .pushQuoteInNewDetail(
                        address
                    )
                )
            )
        case let .like(address):
            store.send(
                .requestUpdateLikeStatus(
                    address,
                    liked: true
                )
            )
        case let .unlike(address):
            store.send(
                .requestUpdateLikeStatus(
                    address,
                    liked: false
                )
            )
        }
    }

    var body: some View {
        DetailStackView(
            app: app,
            store: store.viewStore(
                get: NotebookDetailStackCursor.get,
                tag: NotebookDetailStackCursor.tag
            )
        ) {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    EntryListView(
                        entries: store.state.recent,
                        likes: store.state.likes,
                        onRefresh: {
                            app.send(.syncAll)
                        },
                        notify: self.notify
                    )
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .confirmationDialog(
                        "Are you sure you want to delete this note?",
                        isPresented: Binding(
                            get: { store.state.isConfirmDeleteShowing },
                            send: { action in
                                Task { store.send(action )}
                            },
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
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .navigationTitle("Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    MainToolbar(app: app)
                    
                    ToolbarItemGroup(placement: .principal) {
                        HStack {
                            Text("Notes").bold()
                            CountChip(count: store.state.entryCount)
                        }
                    }
                }
                .onReceive(store.actions) { action in
                    switch action {
                    case .requestScrollToTop:
                        withAnimation(.resetScroll) {
                            proxy.scrollTo(EntryListView.resetScrollTargetId, anchor: .top)
                        }
                    default:
                        return
                    }
                }
            }
        }
    }
}
