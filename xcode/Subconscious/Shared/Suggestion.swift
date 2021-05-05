//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/5/21.
//

import SwiftUI

//  MARK: Suggestion models
struct ThreadSuggestion: Identifiable, Codable {
    var id: String {
        "thread/\(text.hash)"
    }
    var text: String
}

struct QuerySuggestion: Identifiable, Codable {
    var id: String {
        "query/\(text.hash)"
    }
    var text: String
}

struct CreateSuggestion: Identifiable, Codable {
    var id: String {
        "create/\(text.hash)"
    }
    var text: String
}

enum Suggestion {
    case thread(ThreadSuggestion)
    case query(QuerySuggestion)
    case create(CreateSuggestion)
}

extension Suggestion: Identifiable {
    var id: String {
        switch self {
        case .thread(let block):
            return block.id
        case .query(let block):
            return block.id
        case .create(let block):
            return block.id
        }
    }
}

extension Suggestion {
    var text: String {
        switch self {
        case .thread(let block):
            return block.text
        case .query(let block):
            return block.text
        case .create:
            return ""
        }
    }
}

//  MARK: Row View
struct SuggestionRowView: View {
    var suggestion: Suggestion

    var body: some View {
        switch suggestion {
        case .thread(let suggestion):
            Label(suggestion.text, systemImage: "doc.text")
                .lineLimit(1)
        case .query(let suggestion):
            Label(suggestion.text, systemImage: "magnifyingglass")
                .lineLimit(1)
        case .create(let suggestion):
            Label("New: \(suggestion.text)", systemImage: "plus.circle")
                .lineLimit(1)
        }
    }
}

struct SuggestionRow_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionRowView(
            suggestion: Suggestion.query(
                QuerySuggestion(text: "Search term")
            )
        )
    }
}
