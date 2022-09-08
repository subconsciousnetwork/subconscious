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
enum SearchAction: Hashable {
    /// Set search presented state
    case setPresented(Bool)
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
}

//  MARK: Model
struct SearchModel: Hashable {
    /// Is search HUD showing?
    var isPresented = false
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
    ) -> Update<SearchModel, SearchAction> {
        switch action {
        case .setPresented(let isPresented):
            return setPresented(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .cancel:
            return setPresented(
                state: state,
                environment: environment,
                isPresented: false
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
            let searchHistoryFx: Fx<SearchAction> = Just(
                SearchAction.createSearchHistoryItem(query)
            )
            .eraseToAnyPublisher()
            /// Hide after submit
            let fx: Fx<SearchAction> = Just(SearchAction.setPresented(false))
                .merge(with: searchHistoryFx)
                .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
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
        }
    }

    static func setPresented(
        state: SearchModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<SearchModel, SearchAction> {
        var model = state
        model.isPresented = isPresented
        return Update(state: model)
            .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    static func setQuery(
        state: SearchModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<SearchModel, SearchAction> {
        let fx: Fx<SearchAction> = environment.database
            .searchSuggestions(
                query: query,
                isJournalSuggestionEnabled:
                    Config.default.journalSuggestionEnabled,
                isScratchSuggestionEnabled:
                    Config.default.scratchSuggestionEnabled,
                isRandomSuggestionEnabled:
                    Config.default.randomSuggestionEnabled
            )
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
    ) -> Update<SearchModel, SearchAction> {
        let link: EntryLink? = Func.pipe(suggestion) { suggestion  in
            switch suggestion {
            case .entry(let entryLink):
                return entryLink
            case .search(let entryLink):
                return entryLink
            case .journal(let entryLink):
                return entryLink
            case .scratch(let entryLink):
                return entryLink
            default:
                return nil
            }
        }

        let historyFx: Fx<SearchAction> = Func.pipe(link) { link in
            guard let link = link else {
                return Empty().eraseToAnyPublisher()
            }
            return Just(SearchAction.createSearchHistoryItem(link.title))
                .eraseToAnyPublisher()
        }

        let hideSearchFx: Fx<SearchAction> = Just(
            SearchAction.setPresented(false)
        )
        .eraseToAnyPublisher()

        // Duration of keyboard animation
        let duration = Duration.keyboard
        let delay = duration + 0.03

        let fx: Fx<SearchAction> = Just(
            SearchAction.activatedSuggestion(suggestion)
        )
        // Request detail AFTER hide animaiton completes
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .merge(with: historyFx, hideSearchFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Insert search history event into database
    static func createSearchHistoryItem(
        state: SearchModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<SearchModel, SearchAction> {
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
    ) -> Update<SearchModel, SearchAction> {
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
    ) -> Update<SearchModel, SearchAction> {
        environment.logger.warning(
            "Failed to create search history entry: \(error)"
        )
        return Update(state: state)
    }
}

//  MARK: View
struct SearchView: View {
    var store: ViewStore<SearchModel, SearchAction>
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
            isPresented: store.binding(
                get: \.isPresented,
                tag: SearchAction.setPresented
            ),
            content: VStack(alignment: .leading, spacing: 0) {
                HStack {
                    SearchTextField(
                        placeholder: "Search or create...",
                        text: store.binding(
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

struct SearchView2_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            store: ViewStore.constant(
                state: SearchModel(isPresented: true)
            )
        )
    }
}
