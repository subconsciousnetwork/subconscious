//
//  Search.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/6/22.
//
//  Search HUD component.
//  - Handles fetching suggestions whenever query changes.

import SwiftUI
import Combine
import ObservableStore

//  MARK: Action
enum SearchAction: Hashable, CustomLogStringConvertible {
    /// Set search presented state
    case setPresented(Bool)
    /// Set search presented to false, and clear query
    case hideAndClearQuery
    /// Cancel search `(proxy for isPresented(false)`)
    case cancel
    /// Set query (text in input) live as you type
    case setQuery(String)
    /// Hit submit ("go") while focused on search field
    case submitQuery(String)
    case setSuggestions([Suggestion])
    case failSuggestions(String)
    /// Refresh results by re-submitting query
    case refreshSuggestions
    /// Handle user activation of suggestion
    case activateSuggestion(Suggestion)
    /// Notify parent of suggeston activation
    case activatedSuggestion(Suggestion)
    case setKeyboardHeight(CGFloat)
    //  Search history
    /// Write a search history event to the database
    case createSearchHistoryItem(String)
    case succeedCreateSearchHistoryItem(String)
    case failCreateSearchHistoryItem(String)

    /// Handle notification of entry delete from somewhere
    case entryDeleted(Slug)

    var logDescription: String {
        switch self {
        case .setSuggestions(let suggestions):
            return "setSuggestions(\(suggestions.count) items)"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Model
struct SearchModel: ModelProtocol {
    /// Is search HUD showing?
    var isPresented = false
    /// Animation duration for hide/show
    var presentAnimationDuration = Duration.keyboard

    /// Placeholder text when empty
    var placeholder = ""
    /// Live input text
    var query = ""
    var suggestions: [Suggestion] = []
    var keyboardHeight: CGFloat = 350

    //  MARK: Update
    static func update(
        state: SearchModel,
        action: SearchAction,
        environment: AppEnvironment
    ) -> Update<SearchModel> {
        switch action {
        case .setPresented(let isPresented):
            return setPresented(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .hideAndClearQuery:
            return hideAndClearQuery(
                state: state,
                environment: environment
            )
        case .cancel:
            return update(
                state: state,
                action: .hideAndClearQuery,
                environment: environment
            )
        case .setQuery(let query):
            return setQuery(
                state: state,
                environment: environment,
                query: query
            )
        case .refreshSuggestions:
            return setQuery(
                state: state,
                environment: environment,
                query: state.query
            )
        case .submitQuery(let query):
            return SearchModel.update(
                state: state,
                actions: [
                    SearchAction.createSearchHistoryItem(query),
                    SearchAction.hideAndClearQuery
                ],
                environment: environment
            )
        case .setSuggestions(let suggestions):
            var model = state
            model.suggestions = suggestions
            return Update(state: model)
        case .failSuggestions(let message):
            environment.logger.warning("\(message)")
            return Update(state: state)
        case .activateSuggestion(let suggestion):
            return activateSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        case .activatedSuggestion:
            environment.logger.debug(
                ".activatedSuggestion should be handled by parent component"
            )
            return Update(state: state)
        case .setKeyboardHeight(let keyboardHeight):
            var model = state
            model.keyboardHeight = keyboardHeight
            return Update(state: model)
        case let .createSearchHistoryItem(query):
            return createSearchHistoryItem(
                state: state,
                environment: environment,
                query: query
            )
        case let .succeedCreateSearchHistoryItem(query):
            return succeedCreateSearchHistoryItem(
                state: state,
                environment: environment,
                query: query
            )
        case let .failCreateSearchHistoryItem(error):
            return failCreateSearchHistoryItem(
                state: state,
                environment: environment,
                error: error
            )
        case .entryDeleted(_):
            // For now, we handle deletion by just refreshing suggestions.
            return update(
                state: state,
                action: .refreshSuggestions,
                environment: environment
            )
        }
    }

    static func setPresented(
        state: SearchModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<SearchModel> {
        var model = state
        model.isPresented = isPresented
        return Update(state: model)
            .animation(
                .easeOutCubic(
                    duration: state.presentAnimationDuration
                )
            )
    }

    /// Hide search and clear query after animation completes
    static func hideAndClearQuery(
        state: SearchModel,
        environment: AppEnvironment
    ) -> Update<SearchModel> {
        /// Delay search clearing until hide animation completes
        let delay = state.presentAnimationDuration
        let fx: Fx<SearchAction> = Just(
            .setQuery("")
        )
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()

        return update(
            state: state,
            action: .setPresented(false),
            environment: environment
        )
        .mergeFx(fx)
    }

    static func setQuery(
        state: SearchModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<SearchModel> {
        let fx: Fx<SearchAction> = environment.database
            .searchSuggestions(query: query)
            .map({ suggestions in
                SearchAction.setSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    SearchAction.failSuggestions(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()

        var model = state
        model.query = query
        return Update(state: model, fx: fx)
    }

    /// Handle suggestion tapped
    static func activateSuggestion(
        state: SearchModel,
        environment: AppEnvironment,
        suggestion: Suggestion
    ) -> Update<SearchModel> {
        let link: EntryLink? = Func.pipe(suggestion) { suggestion  in
            switch suggestion {
            case .entry(let entryLink):
                return entryLink
            case .search(let entryLink):
                return entryLink
            case .scratch(let entryLink):
                return entryLink
            case .random:
                return nil
            }
        }

        // Duration of keyboard animation
        let duration = Duration.keyboard
        let delay = duration + 0.03

        let fx: Fx<SearchAction> = Just(
            SearchAction.activatedSuggestion(suggestion)
        )
        // Request detail AFTER hide animaiton completes
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()

        guard let link = link else {
            return SearchModel.update(
                state: state,
                action: .hideAndClearQuery,
                environment: environment
            )
            .mergeFx(fx)
        }

        return SearchModel.update(
            state: state,
            actions: [
                .createSearchHistoryItem(link.title),
                .hideAndClearQuery
            ],
            environment: environment
        )
        .mergeFx(fx)
    }

    /// Insert search history event into database
    static func createSearchHistoryItem(
        state: SearchModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<SearchModel> {
        let fx: Fx<SearchAction> = environment.database
            .createSearchHistoryItem(query: query)
            .map({ query in
                SearchAction.succeedCreateSearchHistoryItem(query)
            })
            .catch({ error in
                Just(
                    SearchAction.failCreateSearchHistoryItem(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle success case for search history item creation
    static func succeedCreateSearchHistoryItem(
        state: SearchModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<SearchModel> {
        environment.logger.log(
            "Created search history entry: \(query)"
        )
        return Update(state: state)
    }

    /// Handle failure case for search history item creation
    static func failCreateSearchHistoryItem(
        state: SearchModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<SearchModel> {
        environment.logger.warning(
            "Failed to create search history entry: \(error)"
        )
        return Update(state: state)
    }
}

//  MARK: View
struct SearchView: View {
    var store: ViewStore<SearchModel>
    var suggestionHeight: CGFloat = 56

    /// Calculate maxHeight given number of suggestions.
    /// This allows us to adapt the height of the modal to the
    /// suggestions that are returned.
    private func calcMaxHeight() -> CGFloat {
        CGFloat.minimum(
            suggestionHeight * CGFloat(store.state.suggestions.count),
            suggestionHeight * 6
        )
    }

    var body: some View {
        ModalView(
            isPresented: Binding(
                store: store,
                get: \.isPresented,
                tag: SearchAction.setPresented
            ),
            content: VStack(alignment: .leading, spacing: 0) {
                HStack {
                    SearchTextField(
                        placeholder: store.state.placeholder,
                        text: Binding(
                            store: store,
                            get: \.query,
                            tag: SearchAction.setQuery
                        ),
                        autofocus: true
                    )
                    .submitLabel(.go)
                    .onSubmit {
                        store.send(.submitQuery(store.state.query))
                    }
                    Button(
                        action: {
                            store.send(.cancel)
                        },
                        label: {
                            Text("Cancel")
                        }
                    )
                }
                .frame(height: AppTheme.unit * 10)
                .padding(AppTheme.tightPadding)
                List(store.state.suggestions) { suggestion in
                    Button(
                        action: {
                            store.send(.activateSuggestion(suggestion))
                        },
                        label: {
                            SuggestionLabelView(suggestion: suggestion)
                        }
                    )
                    .modifier(
                        SuggestionViewModifier(
                            // Set suggestion height explicitly so we can
                            // rely on it for our search modal height
                            // calculations.
                            // 2022-02-17 Gordon Brander
                            height: suggestionHeight
                        )
                    )
                }
                // Fix the height of the scrollview based on the number of
                // elements present.
                //
                // This allows us to shrink the modal when there are only a
                // few elements to show.
                //
                // 2022-01-28 Gordon Brander
                .frame(maxHeight: calcMaxHeight())
                .listStyle(.plain)
                .padding(.bottom, AppTheme.tightPadding)
            }
            .background(Color.background),
            keyboardHeight: store.state.keyboardHeight
        )
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            store: ViewStore.constant(
                state: SearchModel(
                    isPresented: true,
                    placeholder: "Search or create..."
                )
            )
        )
    }
}
