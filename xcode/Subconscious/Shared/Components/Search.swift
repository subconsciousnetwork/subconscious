//
//  SearchView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI
import Combine
import os

// MARK:  Action
enum SearchAction {
    case item(_ item: ItemAction<URL, EntryAction>)
    case setItems(_ documents: [TextDocument])
    case requestEdit(url: URL)
}

//  MARK: Model
struct SearchModel: Equatable {
    var entries: [EntryModel]
    
    init(documents: [TextDocument]) {
        self.entries = documents
            .enumerated()
            .map({ (i, document) in
                EntryModel(
                    url: document.url,
                    dom: Subtext(markup: document.content),
                    isFolded: i > 0
                )
            })
    }
}


//  MARK: Update
func updateSearch(
    state: inout SearchModel,
    action: SearchAction,
    environment: Logger
) -> AnyPublisher<SearchAction, Never> {
    switch action {
    case .item(let action):
        // Am I getting a copy, rather than a reference?
        // Is that why it never changes?
        if let i = state.entries.firstIndex(
            where: { entry in entry.id ==  action.key }
        ) {
            let id = state.entries[i].id
            return updateEntry(
                state: &state.entries[i],
                action: action.action,
                environment: environment
            ).map({ action in
                tagSearchItem(
                    key: id,
                    action: action
                )
            }).eraseToAnyPublisher()
        } else {
            environment.info(
                """
                SearchAction.item
                Passed non-existant item key: \(action.key).

                This can happen if an effect is issued from an item,
                and then the item is removed before the effect generates
                a response action.
                """
            )
        }
    case .setItems(let documents):
        state.entries = documents
            .enumerated()
            .map({ (i, doc) in
                EntryModel(
                    url: doc.url,
                    dom: Subtext(markup: doc.content),
                    isFolded: i > 0
                )
            })
    case .requestEdit:
        environment.warning(
            """
            SearchAction.requestEdit
            This action should have been handled by parent view.
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: Tagging
func tagSearchItem(key: URL, action: EntryAction) -> SearchAction {
    switch action {
    case .requestEdit(let url):
        return .requestEdit(url: url)
    default:
        return .item(ItemAction(
            key: key,
            action: action
        ))
    }
}

//  MARK: View
struct SearchView: View, Equatable {
    let store: ViewStore<SearchModel, SearchAction>

    var body: some View {
        ScrollView {
            // LazyVStack creates items only when they need to be rendered
            // onscreen.
            // <https://developer.apple.com/documentation/swiftui/lazyvstack>
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(store.state.entries) { entry in
                    EntryView(
                        store: ViewStore(
                            state: entry,
                            send: store.send,
                            tag: { action in
                                tagSearchItem(
                                    key: entry.id,
                                    action: action
                                )
                            }
                        )
                    )
                    .equatable()
                }
            }
            Spacer()
        }
        .padding(0)
        .background(Color.Sub.secondaryBackground)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            store: ViewStore(
                state: SearchModel(
                    documents: []
                ),
                send: { action in }
            )
        )
    }
}
