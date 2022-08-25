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
    // Feed
    /// Fetch stories for feed
    case fetchFeed
    /// Set stories
    case setFeed([Story])
    /// Fetch feed failed
    case failFetchFeed(Error)
}

extension FeedAction {
    /// Generates a short (approximately 1 line) loggable string for action.
    func toLogString() -> String {
        switch self {
        case .setFeed(let items):
            return "setFeed(...) (\(items.count) items)"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Model
/// A feed of stories
struct FeedModel: Hashable, Equatable {
    var stories: [Story] = []
}

//  MARK: Update
extension FeedModel {
    static func update(
        state: FeedModel,
        action: FeedAction,
        environment: AppEnvironment
    ) -> Update<FeedModel, FeedAction> {
        switch action {
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
        }
    }

    /// Log error at log level
    static func log(
        state: FeedModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<FeedModel, FeedAction> {
        environment.logger.log("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Log error at warning level
    static func warn(
        state: FeedModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<FeedModel, FeedAction> {
        environment.logger.warning("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Fetch latest from feed
    static func fetchFeed(
        state: FeedModel,
        environment: AppEnvironment
    ) -> Update<FeedModel, FeedAction> {
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
    ) -> Update<FeedModel, FeedAction> {
        var model = state
        model.stories = stories
        return Update(state: model)
    }
}

//  MARK: View
struct FeedView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                ForEach(store.state.feed.stories) { story in
                    StoryView(
                        story: story,
                        action: { link in
                        }
                    )
                }
            }
        }
    }
}
