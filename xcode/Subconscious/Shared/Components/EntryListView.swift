//
//  EntryList.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI
import Combine
import os
import Elmo

// MARK:  Action
enum EntryListAction {
    case item(_ item: ItemAction<URL, EntryAction>)
    case search(String)
    case searchSuccess([EntryFile])
    case searchFailure(message: String)
    case requestEdit(url: URL)
}


//  MARK: Model
struct EntryListModel: Equatable {
    var entries: [EntryModel]
    
    init(_ entries: [EntryFile]) {
        self.entries = entries
            .enumerated()
            .map({ (i, wrapper) in
                EntryModel(
                    url: wrapper.url,
                    dom: wrapper.entry.dom,
                    isFolded: i > 0
                )
            })
    }
}


//  MARK: Update
func updateEntryList(
    state: inout EntryListModel,
    action: EntryListAction,
    environment: IOService
) -> AnyPublisher<EntryListAction, Never> {
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
                environment: environment.logger
            ).map({ action in
                tagEntryListItem(
                    key: id,
                    action: action
                )
            }).eraseToAnyPublisher()
        } else {
            environment.logger.info(
                """
                EntryListAction.item
                Passed non-existant item key: \(action.key).

                This can happen if an effect is issued from an item,
                and then the item is removed before the effect generates
                a response action.
                """
            )
        }
    case .search(let query):
        return environment.database.search(query: query)
            .map({ results in
                .searchSuccess(results)
            })
            .catch({ error in
                Just(.searchFailure(message: error.localizedDescription))
            }).eraseToAnyPublisher()
    case .searchSuccess(let entries):
        state.entries = entries
            .enumerated()
            .map({ (i, wrapper) in
                EntryModel(
                    url: wrapper.url,
                    dom: wrapper.entry.dom,
                    isFolded: i > 0
                )
            })
    case .searchFailure(let message):
        environment.logger.warning("\(message)")
    case .requestEdit:
        environment.logger.debug(
            """
            EntryListAction.requestEdit
            This action should have been handled by parent view.
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: Tagging
func tagEntryListItem(key: URL, action: EntryAction) -> EntryListAction {
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
struct EntryListView: View, Equatable {
    let store: ViewStore<EntryListModel, EntryListAction>

    var body: some View {
        ScrollView {
            // LazyVStack creates items only when they need to be rendered
            // onscreen.
            // <https://developer.apple.com/documentation/swiftui/lazyvstack>
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(store.state.entries) { entry in
                    EntryView(
                        store: ViewStore(
                            state: entry,
                            send: store.send,
                            tag: { action in
                                tagEntryListItem(
                                    key: entry.id,
                                    action: action
                                )
                            }
                        )
                    )
                    .equatable()
                    Divider()
                }
            }
        }
    }
}

struct EntryListView_Previews: PreviewProvider {
    static var previews: some View {
        EntryListView(
            store: ViewStore(
                state: EntryListModel([]),
                send: { action in }
            )
        )
    }
}
