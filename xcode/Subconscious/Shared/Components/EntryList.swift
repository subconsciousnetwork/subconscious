//
//  EntryList.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI
import Combine
import os

// MARK:  Action
enum EntryListAction {
    case item(_ item: ItemAction<URL, EntryAction>)
    case setItems(_ entries: [TextEntry])
    case requestEdit(url: URL)
}

//  MARK: Model
struct EntryListModel: Equatable {
    var entries: [EntryModel]
    
    init(entries: [TextEntry]) {
        self.entries = entries
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
func updateEntryList(
    state: inout EntryListModel,
    action: EntryListAction,
    environment: Logger
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
                environment: environment
            ).map({ action in
                tagEntryListItem(
                    key: id,
                    action: action
                )
            }).eraseToAnyPublisher()
        } else {
            environment.info(
                """
                EntryListAction.item
                Passed non-existant item key: \(action.key).

                This can happen if an effect is issued from an item,
                and then the item is removed before the effect generates
                a response action.
                """
            )
        }
    case .setItems(let entries):
        state.entries = entries
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
            LazyVStack(alignment: .leading, spacing: 8) {
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
                }
            }
            Spacer()
        }
        .padding(0)
        .background(Color.Sub.secondaryBackground)
    }
}

struct EntryListView_Previews: PreviewProvider {
    static var previews: some View {
        EntryListView(
            store: ViewStore(
                state: EntryListModel(
                    entries: []
                ),
                send: { action in }
            )
        )
    }
}
