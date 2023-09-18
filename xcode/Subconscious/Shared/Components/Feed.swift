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
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let feed = store.state.entries {
                        ForEach(feed) { entry in
                            if let author = entry.author {
                                StoryEntryView(
                                    story: StoryEntry(
                                        author: author,
                                        entry: entry
                                    ),
                                    action: { address, _ in
                                        store.send(.detailStack(.pushDetail(
                                            MemoDetailDescription.from(
                                                address: address,
                                                fallback: ""
                                            )
                                        )))
                                    }
                                )
                            }
                        }
                    } else {
                        FeedPlaceholderView()
                    }
                }
                
                if let count = store.state.entries?.count,
                   count == 0 {
                    EmptyStateView()
                } else {
                    FabSpacerView()
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
                    state: store.state.search,
                    send: Address.forward(
                        send: store.send,
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
    }
}

extension FeedAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .succeedIndexOurSphere(_):
            return .refreshAll
        case .succeedIndexPeer(_):
            return .refreshAll
        case .requestFeedRoot:
            return .requestFeedRoot
        default:
            return nil
        }
    }
}

//  MARK: Action
enum FeedAction {
    case search(SearchAction)
    case detailStack(DetailStackAction)

    /// Set search view presented
    case setSearchPresented(Bool)

    case ready

    case refreshAll

    // Feed
    /// Fetch stories for feed
    case fetchFeed
    /// Set stories
    case setFeed([EntryStub])
    /// Fetch feed failed
    case failFetchFeed(Error)
    case activatedSuggestion(Suggestion)

    case requestFeedRoot
}

extension FeedAction: CustomLogStringConvertible {
    var logDescription: String {
        switch self {
        case .search(let action):
            return "search(\(String.loggable(action)))"
        case .setFeed(let items):
            return "setFeed(\(items.count) items)"
        default:
            return String(describing: self)
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
        .detailStack(action)
    }
}

//  MARK: Model
/// A feed of stories
struct FeedModel: ModelProtocol {
    /// Search HUD
    var isSearchPresented = false
    /// Search HUD
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    /// Entry detail
    var detailStack = DetailStackModel()
    var entries: [EntryStub]? = nil

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
        case .setFeed(let entries):
            return setFeed(
                state: state,
                environment: environment,
                entries: entries
            )
        case .failFetchFeed(let error):
            return log(state: state, environment: environment, error: error)
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
                FeedAction.setFeed(stories)
            })
            .catch({ error in
                Just(FeedAction.failFetchFeed(error))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Set feed response
    static func setFeed(
        state: FeedModel,
        environment: AppEnvironment,
        entries: [EntryStub]
    ) -> Update<FeedModel> {
        var model = state
        model.entries = entries
        return Update(state: model)
    }

    /// Handle entry deleted
    static func entryDeleted(
        state: FeedModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<FeedModel> {
        logger.warning("Not implemented")
        return Update(state: state)
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
}
