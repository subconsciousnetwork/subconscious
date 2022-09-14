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
    case appear

    case refreshAll

    // Feed
    /// Fetch stories for feed
    case fetchFeed
    /// Set stories
    case setFeed([Story])
    /// Fetch feed failed
    case failFetchFeed(Error)
    case activatedSuggestion(Suggestion)
    case openStory(EntryLink)

    //  Entry deletion
    case requestDeleteEntry(Slug?)
    case entryDeleted(Slug)

    /// Show/hide the search HUD
    static func setSearchPresented(_ isPresented: Bool) -> FeedAction {
        .search(.setPresented(isPresented))
    }

    static func presentDetail(_ isPresented: Bool) -> FeedAction {
        .detail(.presentDetail(isPresented))
    }

    /// Show/hide the search HUD
    static var autosave: FeedAction {
        .detail(.autosave)
    }
}

extension FeedAction: CustomLogStringConvertible {
    var logDescription: String {
        switch self {
        case .detail(let action):
            return "detail(\(String.loggable(action)))"
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
        case .requestDeleteEntry(let slug):
            return .requestDeleteEntry(slug)
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
        case .appear:
            return appear(
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
        case .openStory(let entryLink):
            return FeedDetailCursor.update(
                state: state,
                action: .requestDetail(
                    slug: entryLink.slug,
                    fallback: entryLink.linkableTitle,
                    autofocus: false
                ),
                environment: environment
            )
        case .requestDeleteEntry(_):
            environment.logger.debug(
                "requestDeleteEntry should be handled by parent component"
            )
            return Update(state: state)
        case .entryDeleted(let slug):
            return entryDeleted(
                state: state,
                environment: environment,
                slug: slug
            )
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

    /// Handle appear lifecycle action.
    /// Currently this just calls out to `fetchFeed`. In future it may do more.
    static func appear(
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
        let searchFx: Fx<FeedAction> = Just(
            FeedAction.search(.refreshSuggestions)
        )
        .eraseToAnyPublisher()

        let fx: Fx<FeedAction> = Just(
            FeedAction.fetchFeed
        )
        .merge(with: searchFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
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

    /// Handle entry deleted
    static func entryDeleted(
        state: FeedModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<FeedModel> {
        let searchFx: Fx<FeedAction> = Just(
            FeedAction.search(.entryDeleted(slug))
        )
        .eraseToAnyPublisher()

        let fx: Fx<FeedAction> = Just(
            FeedAction.detail(.entryDeleted(slug))
        )
            .merge(with: searchFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
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
                            get: \.detail.isPresented,
                            tag: FeedAction.presentDetail
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
