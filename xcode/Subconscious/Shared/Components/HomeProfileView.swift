//
//  ProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 6/9/2023.
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: {
                            app.send(.presentSettingsSheet(true))
                        }
                    ) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

//  MARK: View
/// The file view for notes
struct HomeProfileView: View {
    /// Global shared store
    @ObservedObject var app: Store<AppModel>
    /// Local major view store
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
        /// Replay some app actions on notebook store
        .onReceive(
            app.actions.compactMap(HomeProfileAction.from),
            perform: store.send
        )
        /// Replay select notebook actions on app
        .onReceive(
            store.actions.compactMap(AppAction.from),
            perform: app.send
        )
        .onReceive(store.actions) { action in
            let message = String.loggable(action)
            HomeProfileModel.logger.debug("[action] \(message)")
        }
    }
}


//  MARK: Action
enum HomeProfileAction {
    /// Tagged action for detail stack
    case detailStack(DetailStackAction)
    /// Sent by `task` when the view first appears
    case appear
    /// App database is ready. We rely on parent to notify us of this event.
    case ready
    
    case requestHomeProfile
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
    /// Map select app actions to `NotebookAction`
    /// Used to replay select app actions on note store.
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .succeedIndexOurSphere(_):
            return .ready
        case .requestHomeProfile:
            return .requestHomeProfile
        default:
            return nil
        }
    }
}

extension AppAction {
    static func from(_ action: HomeProfileAction) -> Self? {
        switch action {
        default:
            return nil
        }
    }
}

//  MARK: Model
/// Model containing state for the notebook tab.
struct HomeProfileModel: ModelProtocol {
    var isFabShowing = true
    
    /// Contains notebook detail panels
    var detailStack = DetailStackModel()
    var details: [MemoDetailDescription] {
        detailStack.details
    }
    
    /// Main update function
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
        case .requestHomeProfile:
            return requestHomeProfile(
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
    
    static func requestHomeProfile(
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
