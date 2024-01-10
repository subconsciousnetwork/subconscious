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
            ScrollViewReader { proxy in
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
                .onReceive(store.actions) { action in
                    switch action {
                    case .requestScrollToTop:
                        withAnimation(.resetScroll) {
                            proxy.scrollTo(0, anchor: .top)
                        }
                    default:
                        return
                    }
                }
            }
        }
    }
}

// MARK: View
struct HomeProfileView: View {
    @ObservedObject var app: Store<AppModel>
    @StateObject private var store = Store(
        state: HomeProfileModel(),
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: Logger(
            subsystem: Config.default.rdns,
            category: "HomeProfileStore"
        )
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
            
            VStack {
                ToastStackView(
                    store: app.viewStore(
                        get: \.toastStack,
                        tag: ToastStackCursor.tag
                    )
                )
                Spacer()
            }
            .zIndex(3)
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
    }
}


// MARK: Action
enum HomeProfileAction: Hashable {
    case search(SearchAction)
    case activatedSuggestion(Suggestion)
    case detailStack(DetailStackAction)
    case appear
    case ready
    
    case setSearchPresented(Bool)
    case requestProfileRoot
    case requestScrollToTop
    
    /// Note lifecycle events.
    /// `request`s are passed up to the app root
    /// `succeed`s are passed down from the app root
    case requestDeleteEntry(Slashlink?)
    case succeedDeleteEntry(Slashlink)
    case requestSaveEntry(_ entry: MemoEntry)
    case succeedSaveEntry(_ address: Slashlink, _ modified: Date)
    case requestMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case requestMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case requestUpdateAudience(_ address: Slashlink, _ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
    case requestAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
    case succeedAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
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
        case let .requestSaveEntry(entry):
            return .requestSaveEntry(entry)
        case let .requestDeleteEntry(entry):
            return .requestDeleteEntry(entry)
        case let .requestMoveEntry(from, to):
            return .requestMoveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .requestMergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .requestUpdateAudience(address, audience)
        case let .requestAssignNoteColor(address, color):
            return .requestAssignNoteColor(address, color)
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
        case let .succeedDeleteEntry(entry):
            return .succeedDeleteEntry(entry)
        case let .succeedSaveEntry(address, modified):
            return .succeedSaveEntry(address, modified)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        case let .succeedAssignNoteColor(address, color):
            return .succeedAssignNoteColor(address, color)
        default:
            return nil
        }
    }
}

extension AppAction {
    static func from(_ action: HomeProfileAction) -> Self? {
        switch action {
        case let .requestDeleteEntry(entry):
            return .deleteEntry(entry)
        case let .requestSaveEntry(entry):
            return .saveEntry(entry)
        case let .requestMoveEntry(from, to):
            return .moveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .mergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .updateAudience(address: address, audience: audience)
        case let .requestAssignNoteColor(address, color):
            return .assignColor(addess: address, color: color)
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
        case let .succeedSaveEntry(address, modified):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedSaveEntry(address, modified)),
                    .appear
                ],
                environment: environment
            )
        case .succeedDeleteEntry(let address):
            return succeedDeleteEntry(
                state: state,
                environment: environment,
                address: address
            )
        case let .succeedUpdateAudience(receipt):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedUpdateAudience(receipt)),
                    .appear
                ],
                environment: environment
            )
        case let .succeedMoveEntry(from, to):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedMoveEntry(from: from, to: to)),
                    .appear
                ],
                environment: environment
            )
        case let .succeedMergeEntry(parent, child):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedMergeEntry(parent: parent, child: child)),
                    .appear
                ],
                environment: environment
            )
        case let .succeedAssignNoteColor(address, color):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedAssignNoteColor(address, color)),
                    .appear
                ],
                environment: environment
            )
        case .requestDeleteEntry, .requestSaveEntry, .requestMoveEntry,
                .requestMergeEntry, .requestUpdateAudience, .requestScrollToTop,
                .requestAssignNoteColor:
            return Update(state: state)
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
        if state.details.isEmpty {
            let fx: Fx<HomeProfileAction> = Just(.requestScrollToTop).eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        }
        
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
            action: .detailStack(.requestDeleteEntry(address)),
            environment: environment
        )
    }
    
    /// Entry delete succeeded
    static func succeedDeleteEntry(
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
            action: .detailStack(.succeedDeleteEntry(address)),
            environment: environment
        )
    }
}
