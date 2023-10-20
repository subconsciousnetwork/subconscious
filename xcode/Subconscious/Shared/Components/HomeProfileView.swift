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
    
    static func tag(action: UserProfileDetailNotification) -> HomeProfileModel.Action {
        return HomeProfileDetailStackCursor.tag(DetailStackAction.tag(action))
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
                        send: store.send,
                        tag: HomeProfileNavigationView.tag
                    )
                )
            }
        }
    }
}

// MARK: View
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
            .zIndex(1)
            
            if store.state.isSearchPresented {
                SearchView(
                    store: store.viewStore(
                        get: \.search,
                        tag: HomeProfileSearchCursor.tag
                    )
                )
                .zIndex(3)
                .transition(SearchView.presentTransition)
            }
            PinTrailingBottom(
                content: FABView(
                    action: {
                        store.send(.setSearchPresented(true))
                    }
                )
                .padding()
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .zIndex(2)
        }
        .onAppear {
            store.send(.appear)
        }
        /// Replay some app actions on store
        .onReceive(
            app.actions.compactMap(HomeProfileAction.from),
            perform: store.send
        )
        /// Replay some store actions on app
        .onReceive(
            store.actions.compactMap(AppAction.from),
            perform: app.send
        )
        .onReceive(store.actions) { action in
            HomeProfileAction.logger.debug("\(String(describing: action))")
        }
    }
}


// MARK: Action
enum HomeProfileAction {
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "HomeProfileAction"
    )
    
    case search(SearchAction)
    case activatedSuggestion(Suggestion)
    case detailStack(DetailStackAction)
    case appear
    case ready
    case refreshAll
    
    case setSearchPresented(Bool)
    case requestProfileRoot
    
    /// DetailStack-related actions
    case requestDeleteMemo(Slashlink?)
    case succeedDeleteMemo(Slashlink)
    case failDeleteMemo(String)
}

// MARK: Cursors and tagging functions
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
        switch action {
        case let .requestDeleteMemo(slashlink):
            return .requestDeleteMemo(slashlink)
        default:
            return .detailStack(action)
        }
    }
}

extension HomeProfileAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .succeedIndexOurSphere(_):
            return .ready
        case .requestProfileRoot:
            return .requestProfileRoot
        case let .succeedDeleteMemo(address):
            return .succeedDeleteMemo(address)
        case let .failDeleteMemo(error):
            return .failDeleteMemo(error)
        default:
            return nil
        }
    }
}

extension AppAction {
    static func from(_ action: HomeProfileAction) -> Self? {
        switch action {
        case let .requestDeleteMemo(slashlink):
            return .deleteMemo(slashlink)
        default:
            return nil
        }
    }
}

struct HomeProfileSearchCursor: CursorProtocol {
    typealias Model = HomeProfileModel
    typealias ViewModel = SearchModel

    static func get(state: Model) -> ViewModel {
        state.search
    }

    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.search = inner
        return model
    }

    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .activatedSuggestion(let suggestion):
            return .activatedSuggestion(suggestion)
        case .requestPresent(let isPresented):
            return .setSearchPresented(isPresented)
        default:
            return .search(action)
        }
    }
}

// MARK: Model
struct HomeProfileModel: ModelProtocol {
    /// Search HUD
    var isSearchPresented = false
    /// Search HUD
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    
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
        case .search(let action):
            return HomeProfileSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .setSearchPresented(let isPresented):
            return setSearchPresented(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
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
        case .refreshAll:
            return refreshAll(
                state: state,
                environment: environment
            )
        case .requestProfileRoot:
            return requestProfileRoot(
                state: state,
                environment: environment
            )
        case let .activatedSuggestion(suggestion):
            return HomeProfileDetailStackCursor.update(
                state: state,
                action: DetailStackAction.fromSuggestion(suggestion),
                environment: environment
            )
        case .requestDeleteMemo(let address):
            return requestDeleteMemo(
                state: state,
                environment: environment,
                address: address
            )
        case .failDeleteMemo(let error):
            return failDeleteMemo(
                state: state,
                environment: environment,
                error: error
            )
        case .succeedDeleteMemo(let address):
            return succeedDeleteMemo(
                state: state,
                environment: environment,
                address: address
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
    
    static func refreshAll(
        state: Self,
        environment: AppEnvironment
    ) -> Update<Self> {
        logger.debug("TODO: implement refreshAll")
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
    
    /// Set search presented flag
    static func setSearchPresented(
        state: Self,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isSearchPresented = isPresented
        return Update(state: model)
    }
    
    /// Entry delete succeeded
    static func requestDeleteMemo(
        state: Self,
        environment: Environment,
        address: Slashlink?
    ) -> Update<Self> {
        logger.log(
            "Request delete memo",
            metadata: [
                "address": address?.description ?? ""
            ]
        )
        return update(
            state: state,
            action: .detailStack(.requestDeleteMemo(address)),
            environment: environment
        )
    }
    
    /// Entry delete succeeded
    static func succeedDeleteMemo(
        state: Self,
        environment: Environment,
        address: Slashlink
    ) -> Update<Self> {
        logger.log(
            "Memo was deleted",
            metadata: [
                "address": address.description
            ]
        )
        return update(
            state: state,
            actions: [
                .detailStack(.succeedDeleteMemo(address)),
                .refreshAll
            ],
            environment: environment
        )
    }

    /// Entry delete failed
    static func failDeleteMemo(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        logger.log(
            "Failed to delete memo",
            metadata: [
                "error": error
            ]
        )
        return update(
            state: state,
            action: .detailStack(.failDeleteMemo(error)),
            environment: environment
        )
    }
}
