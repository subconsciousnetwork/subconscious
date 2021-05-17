//
//  SuggestionListView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI
import Combine

enum SuggestionListAction {
    case select(_ suggestion: Suggestion)
}

//  MARK: Suggestions list view

/// A single list for ranked suggestions of multiple kinds
///
/// Deliberately does not animate row changes. This view is for type-ahead search, where these animations
/// would be distracting.
///
/// Deliberately does not handle scrolling. This is meant to be placed within a ScrollView along with other
/// types of search results.
struct SuggestionListView: View, Equatable {
    let store: ViewStore<[Suggestion], SuggestionListAction>
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(store.state) { suggestion in
                Button(action: {
                    store.send(.select(suggestion))
                }) {
                    SuggestionRowView(
                        suggestion: suggestion
                    )
                    .foregroundColor(Color.Subconscious.text)
                }
                .padding(.trailing, 16)
                .padding(.leading, 0)
                .padding(.vertical, 12)
                Divider()
            }
        }
        .padding(.leading, 16)
    }
}

struct SuggestionListView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionListView(
            store: ViewStore(
                state: [
                    Suggestion.thread(
                        "If you have 70 notecards, you have a movie"
                    ),
                    Suggestion.thread(
                        "Tenuki"
                    ),
                    Suggestion.query(
                        "Notecard"
                    ),
                    Suggestion.create(
                        "Notecard"
                    ),
                ],
                send:  { query in }
            )
        )
    }
}
