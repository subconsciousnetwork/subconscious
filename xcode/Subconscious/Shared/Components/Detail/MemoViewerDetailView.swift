//
//  MemoViewerDetailView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/15/23.
//

import SwiftUI
import Combine
import os
import ObservableStore

/// Display a read-only memo detail view.
/// Used for content from other spheres that we don't have write access to.
struct MemoViewerDetailView: View {
    @StateObject private var store = Store(
        state: MemoViewerDetailModel(),
        environment: AppEnvironment.default
    )

    var description: MemoViewerDetailDescription
    var notify: (MemoViewerDetailNotification) -> Void

    var body: some View {
        VStack {
            if store.state.isLoading {
                MemoViewerDetailLoadingView(
                    notify: notify
                )
            } else {
                MemoViewerDetailLoadedView(
                    title: store.state.title,
                    content: store.state.content,
                    backlinks: store.state.backlinks,
                    notify: notify
                )
            }
        }
        .navigationTitle(store.state.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible)
        .toolbarBackground(Color.background, for: .navigationBar)
        .toolbar(content: {
            DetailToolbarContent(
                address: store.state.address,
                defaultAudience: store.state.defaultAudience,
                onTapOmnibox: {
                }
            )
        })
        .onAppear {
            store.send(.appear(description))
        }
    }
}

struct MemoViewerDetailLoadingView: View {
    var notify: (MemoViewerDetailNotification) -> Void

    var body: some View {
        ProgressView()
    }
}

struct MemoViewerDetailLoadedView: View {
    var title: String
    var content: String
    var backlinks: [EntryStub]
    var notify: (MemoViewerDetailNotification) -> Void
    
    var body: some View {
        BacklinksView(
            backlinks: backlinks,
            onSelect: { link in
                notify(
                    .requestDetail(
                        MemoDetailDescription.from(
                            address: link.address,
                            fallback: link.title
                        )
                    )
                )
            }
        )
    }
}

/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum MemoViewerDetailNotification: Hashable {
    case requestDetail(_ description: MemoDetailDescription)
}

/// A description of a memo detail that can be used to set up the memo
/// detal's internal state.
struct MemoViewerDetailDescription: Hashable {
    var address: MemoAddress
}

enum MemoViewerDetailAction: Hashable {
    case appear(_ description: MemoViewerDetailDescription)
    case setDetail(_ detail: MemoDetailResponse?)
    case failLoadDetail(_ message: String)
}

struct MemoViewerDetailModel: ModelProtocol {
    typealias Action = MemoViewerDetailAction
    typealias Environment = AppEnvironment

    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetail"
    )
    
    var isLoading = true
    var address: MemoAddress?
    var defaultAudience = Audience.local
    var title = ""
    var content = ""
    var backlinks: [EntryStub] = []
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .appear(let description):
            return appear(
                state: state,
                environment: environment,
                description: description
            )
        case .setDetail(let response):
            return setDetail(
                state: state,
                environment: environment,
                response: response
            )
        case .failLoadDetail(let message):
            logger.log("\(message)")
            return Update(state: state)
        }
    }
    
    static func appear(
        state: Self,
        environment: Environment,
        description: MemoViewerDetailDescription
    ) -> Update<Self> {
        var model = state
        model.isLoading = true
        model.address = description.address
        let fx: Fx<Action> = environment.data.readMemoDetailAsync(
            address: description.address
        ).map({ response in
            Action.setDetail(response)
        }).eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    static func setDetail(
        state: Self,
        environment: Environment,
        response: MemoDetailResponse?
    ) -> Update<Self> {
        var model = state
        model.isLoading = false
        // TODO handle loading state
        guard let response = response else {
            return Update(state: model)
        }
        let memo = response.entry.contents
        model.address = response.entry.address
        model.title = memo.title()
        model.content = memo.body
        model.backlinks = response.backlinks
        return Update(state: model)
    }
}
