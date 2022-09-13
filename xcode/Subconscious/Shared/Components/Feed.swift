//
//  FeedView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/22.
//

import SwiftUI
import ObservableStore
import Combine

//  MARK: Action
enum FeedAction {
    case search(SearchAction)
    case detail(DetailAction)
    case showDetail(Bool)
    case appear
    // Feed
    /// Fetch stories for feed
    case fetchFeed
    /// Set stories
    case setFeed([Story])
    /// Fetch feed failed
    case failFetchFeed(Error)
    case activatedSuggestion(Suggestion)
    case openStory(EntryLink)
    
    /// Show/hide the search HUD
    static func setSearchPresented(_ isPresented: Bool) -> FeedAction {
        .search(.setPresented(isPresented))
    }
}

extension FeedAction: CustomLogStringConvertible {
    var logDescription: String {
        switch self {
        case .detail(let action):
            return "feed(\(String.loggable(action)))"
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
        default:
            return .search(action)
        }
    }
}

struct FeedDetailCursor: CursorProtocol {
    typealias Model = FeedModel
    typealias ViewModel = DetailModel

    static func get(state: FeedModel) -> DetailModel {
        state.detail
    }
    
    static func set(state: FeedModel, inner: DetailModel) -> FeedModel {
        var model = state
        model.detail = inner
        return model
    }
    
    static func tag(_ action: DetailAction) -> FeedAction {
        switch action {
        case .showDetail(let isShowing):
            return .showDetail(isShowing)
        default:
            return .detail(action)
        }
    }
}

//  MARK: Model
/// A feed of stories
struct FeedModel: ModelProtocol {
    /// Search HUD
    var search = SearchModel()
    /// Entry detail
    var detail = DetailModel()
    var isDetailShowing = false
    var stories: [Story] = []

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
        case .detail(let action):
            return FeedDetailCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .showDetail(let isShowing):
            return showDetail(
                state: state,
                isShowing: isShowing
            )
        case .appear:
            return appear(
                state: state,
                environment: environment
            )
        case .fetchFeed:
            return fetchFeed(
                state: state,
                environment: environment
            )
        case .setFeed(let stories):
            return setFeed(
                state: state,
                environment: environment,
                stories: stories
            )
        case .failFetchFeed(let error):
            return log(state: state, environment: environment, error: error)
        case .activatedSuggestion(let suggestion):
            return FeedDetailCursor.update(
                state: state,
                action: DetailAction.fromSuggestion(suggestion),
                environment: environment
            )
        case .openStory(_):
            return Update(state: state)
        }
    }

    /// Log error at log level
    static func log(
        state: FeedModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<FeedModel> {
        environment.logger.log("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Log error at warning level
    static func warn(
        state: FeedModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<FeedModel> {
        environment.logger.warning("\(error.localizedDescription)")
        return Update(state: state)
    }

    static func showDetail(
        state: FeedModel,
        isShowing: Bool
    ) -> Update<FeedModel> {
        var model = state
        model.isDetailShowing = isShowing
        return Update(state: model)
    }

    /// Handle appear lifecycle action.
    /// Currently this just calls out to `fetchFeed`. In future it may do more.
    static func appear(
        state: FeedModel,
        environment: AppEnvironment
    ) -> Update<FeedModel> {
        return fetchFeed(state: state, environment: environment)
    }

    /// Fetch latest from feed
    static func fetchFeed(
        state: FeedModel,
        environment: AppEnvironment
    ) -> Update<FeedModel> {
        let fx: Fx<FeedAction> = environment.feed.generate(max: 10)
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
        stories: [Story]
    ) -> Update<FeedModel> {
        var model = state
        model.stories = stories
        return Update(state: model)
    }
}

//  MARK: View
struct FeedView: View {
    var store: ViewStore<FeedModel>

    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(store.state.stories) { story in
                                StoryView(
                                    story: story,
                                    action: { link in
                                        store.send(FeedAction.openStory(link))
                                    }
                                )
                            }
                        }
                    }
                    NavigationLink(
                        isActive: Binding(
                            store: store,
                            get: \.isDetailShowing,
                            tag: FeedAction.showDetail
                        ),
                        destination: {
                            DetailView(
                                store: ViewStore(
                                    store: store,
                                    cursor: FeedDetailCursor.self
                                )
                            )
                        },
                        label: {
                            EmptyView()
                        }
                    )
                }
                .navigationTitle(Text("Latest"))
            }
            .zIndex(1)
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
            SearchView(
                store: ViewStore(
                    store: store,
                    cursor: FeedSearchCursor.self
                )
            )
            .zIndex(3)
        }
    }
}
