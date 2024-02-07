//
//  AppendLinkSearchView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/1/2024.
//

import SwiftUI
import ObservableStore
import Combine
import os

struct AppendLinkSearchView: View {
    @Environment(\.dismiss) private var dismiss
    var store: ViewStore<AppendLinkSearchModel>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ValidatedFormField(
                    placeholder: String(localized: "Enter link for note"),
                    field: store.viewStore(
                        get: \.queryField,
                        tag: AppendLinkSearchQueryFieldCursor.tag
                    ),
                    autoFocus: true
                )
                .modifier(RoundedTextFieldViewModifier())
                .submitLabel(.done)
                .padding(.bottom, AppTheme.padding)
                .padding(.horizontal, AppTheme.padding)
                
                List(store.state.suggestions) { suggestion in
                    Button(
                        action: {
                            store.send(.selectSuggestion(suggestion))
                        },
                        label: {
                            AppendLinkSuggestionLabelView(suggestion: suggestion)
                        }
                    )
                    .modifier(SuggestionViewModifier())
                }
                .listStyle(.plain)
            }
            .navigationTitle("Append link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            })
        }
    }
}

enum AppendLinkSearchAction: Hashable {
    /// Set the address which we will append to the selected note
    case setSubject(_ address: Slashlink?)
    /// Set the query string for the search input field
    case setQuery(_ query: String)
    case queryField(FormFieldAction<String>)
    case refreshSuggestions
    case setSuggestions([AppendLinkSuggestion])
    case failSuggestions(String)
    case selectSuggestion(AppendLinkSuggestion)
}

struct AppendLinkSearchModel: ModelProtocol {
    var subject: Slashlink? = nil
    var queryField: FormField<String, String> = FormField(value: "", validate: { s in s })
    /// Suggestions for appending to a note
    var suggestions: [AppendLinkSuggestion] = []
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AppendLinkSearch"
    )
    
    static func update(
        state: Self,
        action: AppendLinkSearchAction,
        environment: AppEnvironment
    ) -> Update<Self> {
        switch action {
        case let .queryField(action):
            return AppendLinkSearchQueryFieldCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case let .setSubject(subject):
            return setSubject(
                state: state,
                environment: environment,
                subject: subject
            )
        case .setQuery(let query):
            return setQuery(
                state: state,
                environment: environment,
                query: query
            )
        case .refreshSuggestions:
            return update(
                state: state,
                action: .setQuery(state.queryField.value),
                environment: environment
            )
        case .setSuggestions(let suggestions):
            return setSuggestions(
                state: state,
                suggestions: suggestions
            )
        case .failSuggestions(let error):
            return failSuggestions(
                state: state,
                environment: environment,
                error: error
            )
        case .selectSuggestion:
            return Update(state: state)
        }
    }
    
    static func setSubject(
        state: Self,
        environment: AppEnvironment,
        subject: Slashlink?
    ) -> Update<Self> {
        var model = state
        model.subject = subject

        return Update(state: model)
    }
    
    /// Set text of slug field
    static func setQuery(
        state: Self,
        environment: AppEnvironment,
        query: String
    ) -> Update<Self> {
        guard let current = state.subject else {
            logger.log("Append link query updated, but no subject set. Doing nothing.")
            return Update(state: state)
        }
        let fx: Fx<Self.Action> = Future.detached {
            return try await environment.data
                .searchAppendLink(
                    query: query,
                    current: current
                )
        }
        .map({ suggestions in
            .setSuggestions(suggestions)
        })
        .catch({ error in
            Just(
                .failSuggestions(
                    error.localizedDescription
                )
            )
        })
        .eraseToAnyPublisher()
        
        return update(
            state: state,
            action: .queryField(.setValue(input: query)),
            environment: environment
        ).mergeFx(fx)
    }
    
    static func setSuggestions(
        state: Self,
        suggestions: [AppendLinkSuggestion]
    ) -> Update<Self> {
        var model = state
        model.suggestions = suggestions
        return Update(state: model)
    }

    static func failSuggestions(
        state: Self,
        environment: AppEnvironment,
        error: String
    ) -> Update<Self> {
        logger.warning(
            "Failed to read suggestions from database: \(error)"
        )
        return Update(state: state)
    }
}

struct AppendLinkSearchView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
        }
        .sheet(isPresented: .constant(true)) {
            AppendLinkSearchView(
                store: Store(
                    state: AppendLinkSearchModel(
                        subject: Slashlink(
                            peer: Peer.did(
                                Did.local
                            ),
                            slug: Slug(
                                "/loomings"
                            )!
                        ),
                        suggestions: [
                            .append(
                                address: Slashlink(
                                    "@here/loomings"
                                )!,
                                target: Slashlink(
                                    "@here/the-lee-shore"
                                )!
                            )
                        ]
                    ),
                    environment: AppendLinkSearchModel.Environment()
                ).toViewStoreForSwiftUIPreview()
            )
        }
    }
}

struct AppendLinkSearchQueryFieldCursor: CursorProtocol {
    typealias Model = AppendLinkSearchModel
    typealias ViewModel = FormField<String, String>

    static func get(state: Model) -> ViewModel {
        state.queryField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.queryField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch (action) {
        case .setValue(let query):
            return .setQuery(query)
        case _:
            return .queryField(action)
        }
    }
}
