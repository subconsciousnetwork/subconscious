//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/5/21.
//

import SwiftUI

enum Suggestion {
    case thread(_ text: String)
    case query(_ text: String)
    case create(_ text: String)
}

extension Suggestion: Identifiable {
    var id: String {
        switch self {
        case .thread(let text):
            return "thread/\(text.hash)"
        case .query(let text):
            return "query/\(text.hash)"
        case .create(let text):
            return "create/\(text.hash)"
        }
    }
}

extension Suggestion: CustomStringConvertible {
    var description: String {
        switch self {
        case .thread(let text):
            return text
        case .query(let text):
            return text
        case .create(let text):
            return text
        }
    }
}

//  MARK: Row View
struct SuggestionRowView: View {
    var suggestion: Suggestion

    var body: some View {
        switch suggestion {
        case .thread(let text):
            Label(text, systemImage: "doc.text")
                .lineLimit(1)
        case .query(let text):
            Label(text, systemImage: "magnifyingglass")
                .lineLimit(1)
        case .create(let text):
            Label(text, systemImage: "plus.circle")
                .lineLimit(1)
        }
    }
}

struct SuggestionRow_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionRowView(
            suggestion: Suggestion.query("Search term")
        )
    }
}
