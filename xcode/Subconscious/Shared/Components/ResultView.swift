//
//  ResultView.swift
//  ResultView
//
//  Created by Gordon Brander on 9/10/21.
//

import SwiftUI
import Elmo
import Combine
import os

/// View handles interacting with the database, and rendering entry detail
struct ResultView: View, Equatable {
    enum Action {
        case entryDetail(EntryDetailView.Action)
        case search(String)
        case searchSuccess(EntryResults)
        case searchFailure(message: String)
        case commitQuery(String)
    }

    static func tagEntryDetail(_ action: EntryDetailView.Action) -> Action {
        switch action {
        case .commitQuery(let query):
            return .commitQuery(query)
        default:
            return .entryDetail(action)
        }
    }

    struct Model: Equatable {
        var entryDetail: EntryDetailView.Model?
    }

    static func update(
        state: inout Model,
        action: Action,
        environment: IOService
    ) -> AnyPublisher<Action, Never> {
        switch action {
        case .entryDetail(let action):
            if state.entryDetail != nil {
                return EntryDetailView.update(
                    state: &state.entryDetail!,
                    action: action,
                    environment: environment.logger
                ).map(tagEntryDetail).eraseToAnyPublisher()
            }
        case .search(let query):
            // Nil last result, putting view in "loading" state.
            state.entryDetail = nil
            return environment.database.search(query: query)
                .map({ results in
                    .searchSuccess(results)
                })
                .catch({ error in
                    Just(.searchFailure(message: error.localizedDescription))
                }).eraseToAnyPublisher()
        case .searchSuccess(let results):
            state.entryDetail = .init(
                markup: results.entry?.content ?? "",
                backlinks: results.backlinks
            )
        case .searchFailure(let message):
            environment.logger.warning("\(message)")
        case .commitQuery:
            let string = String(reflecting: action)
            environment.logger.debug(
                """
                Action should be handled by parent\t\(string)
                """
            )
        }
        return Empty().eraseToAnyPublisher()
    }
    
    var store: ViewStore<Model, Action>

    var body: some View {
        VStack {
            if let entryDetail = store.state.entryDetail {
                EntryDetailView(
                    store: ViewStore(
                        state: entryDetail,
                        send: store.send,
                        tag: Self.tagEntryDetail
                    )
                ).equatable()
            } else {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .background(Constants.Color.secondaryBackground)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView(
            store: ViewStore(
                state: .init(),
                send: { action in }
            )
        )
    }
}
