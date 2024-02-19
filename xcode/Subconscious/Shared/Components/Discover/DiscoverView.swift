//
//  DiscoverView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/2/2024.
//

import os
import SwiftUI
import ObservableStore
import Combine

struct DiscoverView: View {
    @ObservedObject var app: Store<AppModel>
    @StateObject var store: Store<DiscoverModel> = Store(
        state: DiscoverModel(),
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: Logger(
            subsystem: Config.default.rdns,
            category: "DiscoverStore"
        )
    )
    
    var body: some View {
        ZStack {
            DiscoverNavigationView(app: app, store: store)
                .zIndex(1)
            
            if store.state.isSearchPresented {
                SearchView(
                    store: store.viewStore(
                        get: \.search,
                        tag: DiscoverSearchCursor.tag
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
        .frame(maxWidth: .infinity)
        /// Replay some app actions on deck store
        .onReceive(
            app.actions.compactMap(DiscoverAction.from),
            perform: store.send
        )
        /// Replay some deck actions on app store
        .onReceive(
            store.actions.compactMap(AppAction.from),
            perform: app.send
        )
    }
}

// MARK: Actions
enum DiscoverAction: Hashable {
    case requestDiscoverRoot
    case detailStack(DetailStackAction)
    
    case setSearchPresented(Bool)
    case activatedSuggestion(Suggestion)
    case search(SearchAction)
    
    case appear
    
    case refreshSuggestions
    case succeedRefreshSuggestions(_ suggestions: [AssociateRecord])
    case failRefreshSuggestions(_ error: String)
    
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
    case requestAppendToEntry(_ address: Slashlink, _ append: String)
    case succeedAppendToEntry(_ address: Slashlink)
    case requestUpdateLikeStatus(Slashlink, liked: Bool)
    case succeedUpdateLikeStatus(_ address: Slashlink, liked: Bool)
}

extension AppAction {
    static func from(_ action: DiscoverAction) -> Self? {
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
            return .assignColor(address: address, color: color)
        case let .requestAppendToEntry(address, append):
            return .appendToEntry(address: address, append: append)
        case let .requestUpdateLikeStatus(address, liked):
            return .setLiked(address: address, liked: liked)
        default:
            return nil
        }
    }
}

extension DiscoverAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .requestDiscoverRoot:
            return .requestDiscoverRoot
        case let .succeedSaveEntry(address, modified):
            return .succeedSaveEntry(address, modified)
        case let .succeedDeleteEntry(entry):
            return .succeedDeleteEntry(entry)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        case let .succeedAssignNoteColor(address, color):
            return .succeedAssignNoteColor(address, color)
        case let .succeedAppendToEntry(address):
            return .succeedAppendToEntry(address)
        case let .succeedUpdateLikeStatus(address, liked):
            return .succeedUpdateLikeStatus(address, liked: liked)
        default:
            return nil
        }
    }
}

typealias DiscoverEnvironment = AppEnvironment

struct DiscoverSearchCursor: CursorProtocol {
    typealias Model = DiscoverModel
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

struct DiscoverDetailStackCursor: CursorProtocol {
    typealias Model = DiscoverModel
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
        case let .requestAppendToEntry(address, append):
            return .requestAppendToEntry(address, append)
        case let .requestUpdateLikeStatus(address, liked):
            return .requestUpdateLikeStatus(address, liked: liked)
        case _:
            return .detailStack(action)
        }
    }
}

// MARK: Model
struct DiscoverModel: ModelProtocol {
    public static let backlinksToDraw = 1
    
    typealias Action = DiscoverAction
    typealias Environment = DiscoverEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DiscoverModel"
    )
    
    var detailStack = DetailStackModel()
    var suggestions: [AssociateRecord] = []
    
    var loadingStatus: LoadingState = .loading
    
    /// Search HUD
    var isSearchPresented = false
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    
    var selectionFeedback = UISelectionFeedbackGenerator()
    var feedback = UIImpactFeedbackGenerator()
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch (action) {
        case .detailStack(let action):
            return DiscoverDetailStackCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .search(let action):
            return DiscoverSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case let .setSearchPresented(presented):
            var model = state
            model.isSearchPresented = presented
            return Update(state: model)
        case let .activatedSuggestion(suggestion):
            return DiscoverDetailStackCursor.update(
                state: state,
                action: DetailStackAction.fromSuggestion(suggestion),
                environment: environment
            )
        case .appear:
            return appear(
                state: state,
                environment: environment
            )
        case .requestDiscoverRoot:
            return requestDiscoverRoot(
                state: state,
                environment: environment
            )
        case let .succeedSaveEntry(address, modified):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedSaveEntry(address, modified))
                ],
                environment: environment
            )
        case let .succeedDeleteEntry(address):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedDeleteEntry(address)
                    )
                ],
                environment: environment
            )
        case let .succeedMoveEntry(from, to):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedMoveEntry(
                            from: from,
                            to: to
                        )
                    )
                ],
                environment: environment
            )
        case let .succeedMergeEntry(parent, child):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedMergeEntry(parent: parent, child: child)
                    ),
                ],
                environment: environment
            )
        case let .succeedUpdateAudience(receipt):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedUpdateAudience(receipt)
                    ),
                ],
                environment: environment
            )
        case let .succeedAssignNoteColor(address, color):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedAssignNoteColor(address, color)
                    ),
                ],
                environment: environment
            )
        case let .succeedAppendToEntry(address):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedAppendToEntry(address)
                    ),
                ],
                environment: environment
            )
        case let .succeedUpdateLikeStatus(address, liked):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedUpdateLikeStatus(address, liked: liked)
                    ),
                ],
                environment: environment
            )
        case .refreshSuggestions:
            return refreshSuggestions(
                state: state,
                environment: environment
            )
        case let .succeedRefreshSuggestions(suggestions):
            return succeedRefreshSuggestions(
                state: state,
                environment: environment,
                suggestions: suggestions
            )
        case let .failRefreshSuggestions(error):
            logger.warning("Failed to refresh suggestions: \(error)")
            return Update(state: state)

        case .requestDeleteEntry, .requestSaveEntry, .requestMoveEntry,
                .requestMergeEntry, .requestUpdateAudience, .requestAssignNoteColor,
                .requestAppendToEntry, .requestUpdateLikeStatus:
            return Update(state: state)
        }
        
        func appear(
            state: Self,
            environment: Environment
        ) -> Update<Self> {
            return update(
                state: state,
                action: .refreshSuggestions,
                environment: environment
            )
        }
        
        func requestDiscoverRoot(
            state: Self,
            environment: AppEnvironment
        ) -> Update<Self> {
            return DiscoverDetailStackCursor.update(
                state: state,
                action: .setDetails([]),
                environment: environment
            )
        }
    }
    
    static func refreshSuggestions(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            let suggestions = try environment.database.listAssociates()
            return .succeedRefreshSuggestions(suggestions)
        }
        .recover { error in
            .failRefreshSuggestions(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedRefreshSuggestions(
        state: Self,
        environment: Environment,
        suggestions: [AssociateRecord]
    ) -> Update<Self> {
        var model = state
        model.suggestions = suggestions
        return Update(state: model)
    }
}
