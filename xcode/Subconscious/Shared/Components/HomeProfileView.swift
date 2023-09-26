//
//  HomeProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 19/9/2023.
//

import SwiftUI
import os
import ObservableStore
import Combine

struct HomeProfileNavigationView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<HomeProfileModel>
    var detailStack: ViewStore<DetailStackModel> {
        store.viewStore(
            get: HomeProfileDetailStackCursor.get,
            tag: HomeProfileDetailStackCursor.tag
        )
    }

    var body: some View {
        DetailStackView(
            app: app,
            store: detailStack
        ) {
            VStack(spacing: 0) {
                UserProfileDetailView(
                    app: app,
                    description: UserProfileDetailDescription(address: Slashlink.ourProfile),
                    notify: Address.forward(
                        send: detailStack.send,
                        tag: DetailStackAction.tag
                    )
                )
            }
        }
    }
}

//  MARK: View
struct HomeProfileView: View {
    @ObservedObject var app: Store<AppModel>
    @StateObject private var store = Store(
        state: HomeProfileModel(),
        environment: AppEnvironment.default
    )

    var body: some View {
        ZStack {
            HomeProfileNavigationView(
                app: app,
                store: store
            )
        }
        .onAppear {
            store.send(.appear)
        }
        /// Replay app actions on local store
        .onReceive(
            app.actions.compactMap(HomeProfileAction.from),
            perform: store.send
        )
        .onReceive(store.actions) { action in
            let message = String.loggable(action)
            HomeProfileModel.logger.debug("[action] \(message)")
        }
    }
}


//  MARK: Action
enum HomeProfileAction {
    case detailStack(DetailStackAction)
    case appear
    case ready

    case requestProfileRoot
}

//  MARK: Cursors and tagging functions
struct HomeProfileDetailStackCursor: CursorProtocol {
    typealias Model = HomeProfileModel
    typealias ViewModel = DetailStackModel

    static func get(state: Model) -> ViewModel {
        state.detailStack
    }

    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.detailStack = inner
        return model
    }

    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .detailStack(action)
    }
}

extension HomeProfileAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .succeedIndexOurSphere(_):
            return .ready
        case .requestProfileRoot:
            return .requestProfileRoot
        default:
            return nil
        }
    }
}

//  MARK: Model
struct HomeProfileModel: ModelProtocol {
    var detailStack = DetailStackModel()
    var details: [MemoDetailDescription] {
        detailStack.details
    }

    static func update(
        state: Self,
        action: HomeProfileAction,
        environment: AppEnvironment
    ) -> Update<Self> {
        switch action {
        case let .detailStack(action):
            return HomeProfileDetailStackCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .appear:
            return appear(
                state: state,
                environment: environment
            )
        case .ready:
            return ready(
                state: state,
                environment: environment
            )
        case .requestProfileRoot:
            return requestProfileRoot(
                state: state,
                environment: environment
            )
        }
    }

    // Logger for actions
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "HomeProfileModel"
    )

    /// Just before view appears (sent by task)
    static func appear(
        state: Self,
        environment: AppEnvironment
    ) -> Update<Self> {
        return Update(state: state)
    }

    /// View is ready
    static func ready(
        state: Self,
        environment: AppEnvironment
    ) -> Update<Self> {
        return Update(state: state)
    }

    static func requestProfileRoot(
        state: Self,
        environment: AppEnvironment
    ) -> Update<Self> {
        return HomeProfileDetailStackCursor.update(
            state: state,
            action: .setDetails([]),
            environment: environment
        )
    }
}
