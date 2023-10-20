//
//  FeedView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/22.
//

import SwiftUI
import ObservableStore
import Combine
import os

struct FeedNavigationView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<FeedModel>
    
    var detailStack: ViewStore<DetailStackModel> {
        store.viewStore(
            get: FeedDetailStackCursor.get,
            tag: FeedDetailStackCursor.tag
        )
    }
    
    var body: some View {
        DetailStackView(app: app, store: detailStack) {
            VStack {
                switch (store.state.status, store.state.entries) {
                case (.loading, _):
                    FeedPlaceholderView()
                case let (.loaded, .some(feed)):
                    switch feed.count {
                    case 0:
                        FeedEmptyView(
                            onRefresh: { app.send(.syncAll) }
                        )
                    default:
                        FeedListView(
                            feed: feed,
                            store: store
                        )
                    }
                case (.notFound, _):
                    NotFoundView()
                default:
                    EmptyView()
                }
            }
            .background(Color.background)
            .refreshable {
                app.send(.syncAll)
            }
            .onAppear {
                store.send(.fetchFeed)
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                MainToolbar(
                    app: app,
                    profileAction: {
                        store.send(.detailStack(.requestOurProfileDetail))
                    }
                )
                
                ToolbarItemGroup(placement: .principal) {
                    HStack {
                        Text("Feed").bold()
                    }
                }
            }
        }
    }
}

//  MARK: View
struct FeedView: View {
    @ObservedObject var app: Store<AppModel>
    @StateObject private var store = Store(
        state: FeedModel(),
        environment: AppEnvironment.default
    )
    
    var body: some View {
        ZStack {
            FeedNavigationView(app: app, store: store)
                .zIndex(1)
            
            if store.state.isSearchPresented {
                SearchView(
                    store: store.viewStore(
                        get: \.search,
                        tag: FeedSearchCursor.tag
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
        .background(Color.background)
        /// Replay some app actions on feed store
        .onReceive(
            app.actions.compactMap(FeedAction.from),
            perform: store.send
        )
        /// Replay some feed actions on app store
        .onReceive(
            store.actions.compactMap(AppAction.from),
            perform: app.send
        )
        .onReceive(store.actions) { action in
            FeedAction.logger.debug("\(String(describing: action))")
        }
    }
}

//  MARK: Action
enum FeedAction {
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "FeedAction"
    )

    case search(SearchAction)
    case activatedSuggestion(Suggestion)
    case detailStack(DetailStackAction)

    /// Set search view presented
    case setSearchPresented(Bool)
    case ready
    case refreshAll
    
    /// DetailStack-related actions
    case requestDeleteMemo(Slashlink?)
    case succeedDeleteMemo(Slashlink)
    case failDeleteMemo(String)
    case succeedSaveEntry(slug: Slashlink, modified: Date)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedUpdateAudience(MoveReceipt)
    
    // Feed
    /// Fetch stories for feed
    case fetchFeed
    /// Set stories
    case succeedFetchFeed([StoryEntry])
    /// Fetch feed failed
    case failFetchFeed(Error)
    
    case requestFeedRoot
}

extension AppAction {
    static func from(_ action: FeedAction) -> Self? {
        switch action {
        case let .requestDeleteMemo(slashlink):
            return .deleteMemo(slashlink)
        default:
            return nil
        }
    }
}

extension FeedAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .succeedIndexOurSphere:
            return .refreshAll
        case .succeedIndexPeer:
            return .refreshAll
        case .succeedRecoverOurSphere:
            return .refreshAll
        case .requestFeedRoot:
            return .requestFeedRoot
        case let .succeedDeleteMemo(address):
            return .succeedDeleteMemo(address)
        case let .failDeleteMemo(error):
            return .failDeleteMemo(error)
        default:
            return nil
        }
    }
}

struct FeedSearchCursor: CursorProtocol {
    typealias Model = FeedModel
    typealias ViewModel = SearchModel

    static func get(state: FeedModel) -> SearchModel {
        state.search
    }

    static func set(state: FeedModel, inner: SearchModel) -> FeedModel {
        var model = state
        model.search = inner
        return model
    }

    static func tag(_ action: SearchAction) -> FeedAction {
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

struct FeedDetailStackCursor: CursorProtocol {
    typealias Model = FeedModel
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
        case let .succeedMergeEntry(parent: parent, child: child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedMoveEntry(from: from, to: to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        case let .succeedSaveEntry(address: address, modified: modified):
            return .succeedSaveEntry(slug: address, modified: modified)
        case _:
            return .detailStack(action)
        }
    }
}

//  MARK: Model
/// A feed of stories
struct FeedModel: ModelProtocol {
    var status: LoadingState = .loading
    /// Search HUD
    var isSearchPresented = false
    /// Search HUD
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    /// Entry detail
    var detailStack = DetailStackModel()
    var entries: [StoryEntry]? = nil
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "Feed"
    )
    
    //  MARK: Update
    static func update(
        state: FeedModel,
        action: FeedAction,
        environment: AppEnvironment
    ) -> Update<FeedModel> {
        switch action {
        case .search(let action):
            return FeedSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .detailStack(let action):
            return FeedDetailStackCursor.update(
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
        case .fetchFeed:
            return fetchFeed(
                state: state,
                environment: environment
            )
        case .succeedFetchFeed(let entries):
            return succeedFetchFeed(
                state: state,
                environment: environment,
                entries: entries
            )
        case .failFetchFeed(let error):
            return failFetchFeed(state: state, environment: environment, error: error)
        case let .activatedSuggestion(suggestion):
            return FeedDetailStackCursor.update(
                state: state,
                action: DetailStackAction.fromSuggestion(suggestion),
                environment: environment
            )
        case .requestFeedRoot:
            return requestFeedRoot(
                state: state,
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
        case let .succeedUpdateAudience(receipt):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedUpdateAudience(receipt)),
                    .refreshAll
                ],
                environment: environment
            )
        case let .succeedMoveEntry(from, to):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedMoveEntry(from: from, to: to)),
                    .refreshAll
                ],
                environment: environment
            )
        case let .succeedMergeEntry(parent, child):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedMergeEntry(parent: parent, child: child)),
                    .refreshAll
                ],
                environment: environment
            )
        case let .succeedSaveEntry(address, modified):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedSaveEntry(address: address, modified: modified)),
                    .refreshAll
                ],
                environment: environment
            )
        }
    }
    
    /// Log error at log level
    static func log(
        state: FeedModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<FeedModel> {
        logger.log("\(error.localizedDescription)")
        return Update(state: state)
    }
    
    /// Log error at warning level
    static func warn(
        state: FeedModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<FeedModel> {
        logger.warning("\(error.localizedDescription)")
        return Update(state: state)
    }
    
    /// Set search presented flag
    static func setSearchPresented(
        state: FeedModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<FeedModel> {
        var model = state
        model.isSearchPresented = isPresented
        return Update(state: model)
    }
    
    static func ready(
        state: FeedModel,
        environment: AppEnvironment
    ) -> Update<FeedModel> {
        return fetchFeed(state: state, environment: environment)
    }
    
    /// Refresh all list views from database
    static func refreshAll(
        state: FeedModel,
        environment: AppEnvironment
    ) -> Update<FeedModel> {
        return FeedModel.update(
            state: state,
            actions: [
                .search(.refreshSuggestions),
                .fetchFeed
            ],
            environment: environment
        )
    }
    
    /// Fetch latest from feed
    static func fetchFeed(
        state: FeedModel,
        environment: AppEnvironment
    ) -> Update<FeedModel> {
        let fx: Fx<FeedAction> = environment.data.listFeedPublisher()
            .map({ stories in
                FeedAction.succeedFetchFeed(stories)
            })
            .catch({ error in
                Just(FeedAction.failFetchFeed(error))
            })
            .eraseToAnyPublisher()
        
        var model = state
        // only display loading state if we have no posts to show
        // if we have stale posts, show them until we load the new ones
        if state.entries?.isEmpty ?? false {
            model.status = .loading
        }
        
        return Update(state: model, fx: fx)
    }
    
    /// Set feed response
    static func succeedFetchFeed(
        state: FeedModel,
        environment: AppEnvironment,
        entries: [StoryEntry]
    ) -> Update<FeedModel> {
        var model = state
        model.entries = entries
        model.status = .loaded
        return Update(state: model)
    }
    
    static func failFetchFeed(
        state: FeedModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<FeedModel> {
        logger.error("Failed to fetch feed \(error.localizedDescription)")
        var model = state
        model.status = .notFound
        
        return Update(state: model)
    }
    
    static func requestFeedRoot(
        state: FeedModel,
        environment: AppEnvironment
    ) -> Update<FeedModel> {
        return FeedDetailStackCursor.update(
            state: state,
            action: .setDetails([]),
            environment: environment
        )
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
