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
                
                List(store.state.renameSuggestions) { suggestion in
                    Button(
                        action: {
                            store.send(.selectSuggestion(suggestion))
                        },
                        label: {
                            RenameSuggestionLabelView(suggestion: suggestion)
                        }
                    )
                    .modifier(SuggestionViewModifier())
                }
                .listStyle(.plain)
            }
            .navigationTitle("Edit link")
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
    /// Set the memo for which this rename sheet is being invoked.
    case setSubject(_ address: Slashlink?)
    /// Set the query string for the search input field
    case setQuery(_ query: String)
    case queryField(FormFieldAction<String>)
    case refreshSuggestions
    case setSuggestions([RenameSuggestion])
    case failSuggestions(String)
    case selectSuggestion(RenameSuggestion)
}

struct AppendLinkSearchModel: ModelProtocol {
    var subject: Slashlink? = nil
    var queryField: FormField<String, String> = FormField(value: "", validate: { s in s })
    /// Suggestions for renaming note.
    var renameSuggestions: [RenameSuggestion] = []
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "RenameSearch"
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
            return setRenameSuggestions(
                state: state,
                suggestions: suggestions
            )
        case .failSuggestions(let error):
            return failRenameSuggestions(
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

        let query = subject?.toSlug().description ?? ""

        return update(
            state: model,
            action: .setQuery(query),
            environment: environment
        )
    }
    
    /// Set text of slug field
    static func setQuery(
        state: Self,
        environment: AppEnvironment,
        query: String
    ) -> Update<Self> {
        guard let current = state.subject else {
            logger.log("Rename query updated, but no subject set. Doing nothing.")
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
    
    /// Set rename suggestions
    static func setRenameSuggestions(
        state: Self,
        suggestions: [RenameSuggestion]
    ) -> Update<Self> {
        var model = state
        model.renameSuggestions = suggestions
        return Update(state: model)
    }

    /// Handle rename suggestions error.
    /// This case can happen e.g. if the database fails to respond.
    static func failRenameSuggestions(
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
                        renameSuggestions: [
                            .move(
                                from: Slashlink(
                                    "@here/loomings"
                                )!,
                                to: Slashlink(
                                    "@here/the-lee-shore"
                                )!
                            ),
                            .merge(
                                parent: Slashlink(
                                    "@here/breakfast"
                                )!,
                                child: Slashlink(
                                    "@here/the-street"
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
