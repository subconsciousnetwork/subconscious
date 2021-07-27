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
    case selectRecent
    case selectRecentSuccess([EntryFile])
    case selectRecentFailure(message: String)
    case setItems([EntryFile])
    case requestEdit(url: URL)

    static func fetch(_ query: String) -> Self {
        if query.isWhitespace {
            return .selectRecent
        } else {
            return .search(query)
        }
    }
}


//  MARK: Model
struct EntryListModel: Equatable {
    enum State {
        case loading
        case ready
    }

    var entries: [EntryModel]
    var state: State

    init(_ entries: [EntryFile]) {
        self.state = .ready
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
    case .setItems(let results):
        state.entries = results
            .enumerated()
            .map({ (i, wrapper) in
                EntryModel(
                    url: wrapper.url,
                    dom: wrapper.entry.dom,
                    isFolded: i > 0
                )
            })
        state.state = .ready
    case .search(let query):
        state.state = .loading
        return environment.database.search(query: query)
            .map({ results in
                .searchSuccess(results)
            })
            .catch({ error in
                Just(.searchFailure(message: error.localizedDescription))
            }).eraseToAnyPublisher()
    case .searchSuccess(let results):
        return Just(.setItems(results)).eraseToAnyPublisher()
    case .searchFailure(let message):
        state.state = .ready
        environment.logger.warning("\(message)")
    case .selectRecent:
        state.state = .loading
        return environment.database.selectRecent()
            .map({ results in
                .selectRecentSuccess(results)
            })
            .catch({ error in
                Just(
                    .selectRecentFailure(message: error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
    case .selectRecentSuccess(let results):
        return Just(.setItems(results)).eraseToAnyPublisher()
    case .selectRecentFailure(let message):
        state.state = .ready
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
        if store.state.state == .loading {
            ProgressView()
        } else {
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
