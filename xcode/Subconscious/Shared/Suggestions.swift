//
//  Suggestions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI
import Combine

//  MARK: Suggestions list view
/// A single list for ranked suggestions of multiple kinds
struct SuggestionsView: View {
    var suggestions: [Suggestion]
    let send: (AppAction) -> Void
    
    var body: some View {
        List(suggestions) { suggestion in
            Button(action: {
                send(.query(suggestion.text))
            }) {
                SuggestionRowView(suggestion: suggestion)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionsView(
            suggestions: [
                Suggestion.thread(
                    ThreadSuggestion(text: "If you have 70 notecards, you have a movie")
                ),
                Suggestion.thread(
                    ThreadSuggestion(text: "Tenuki")
                ),
                Suggestion.query(
                    QuerySuggestion(text: "Notecard")
                ),
                Suggestion.create(
                    CreateSuggestion(text: "Notecard")
                ),
            ],
            send:  { query in }
        )
    }
}
