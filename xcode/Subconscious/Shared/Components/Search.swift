//
//  SearchView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI
import Combine
import os

enum SearchAction {
    case item(_ item: ItemAction<Int, ThreadAction>)
    case setItems(_ documents: [SubconsciousDocument])
    case requestEdit(_ document: SubconsciousDocument)
}

struct SearchModel: Equatable {
    var threads: [ThreadModel]
    
    init(documents: [SubconsciousDocument]) {
        self.threads = documents
            .enumerated()
            .map({ (i, doc) in ThreadModel(document: doc, isFolded: i > 0) })
    }
}

func updateSearch(
    state: inout SearchModel,
    action: SearchAction,
    environment: Logger
) -> AnyPublisher<SearchAction, Never> {
    switch action {
    case .item(let action):
        if var thread = state.threads.first(
            where: { thread in thread.id ==  action.key }
        ) {
            return updateThread(
                state: &thread,
                action: action.action,
                environment: environment
            ).map({ action in
                tagSearchItem(
                    key: thread.id,
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
        state.threads = documents
            .enumerated()
            .map({ (i, doc) in ThreadModel(document: doc, isFolded: i > 0) })
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

func tagSearchItem(key: Int, action: ThreadAction) -> SearchAction {
    switch action {
    case .requestEdit(let document):
        return .requestEdit(document)
    default:
        return .item(ItemAction(
            key: key,
            action: action
        ))
    }
}

struct SearchView: View, Equatable {
    let store: ViewStore<SearchModel, SearchAction>

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.state.threads) { thread in
                        ThreadView(
                            store: ViewStore(
                                state: thread,
                                send: store.send,
                                tag: { action in
                                    tagSearchItem(
                                        key: thread.id,
                                        action: action
                                    )
                                }
                            )
                        ).equatable()
                        ThickSeparator().padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.top, 4)
        }
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
