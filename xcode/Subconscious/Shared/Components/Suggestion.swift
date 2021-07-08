//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/5/21.
//

import SwiftUI

enum Suggestion: Equatable {
    case entry(url: URL, title: String)
    case query(_ text: String)
    case create(_ text: String)
}

extension Suggestion: Identifiable {
    var id: String {
        switch self {
        case .entry(_, let title):
            return "entry/\(title.hash)"
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
        case .entry(_, let title):
            return title
        case .query(let text):
            return text
        case .create(let text):
            return text
        }
    }
}

//  MARK: Row View
struct SuggestionRowView: View, Equatable {
    var suggestion: Suggestion

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch suggestion {
                case .entry(_, let title):
                    HStack(spacing: 0) {
                        Label(title, systemImage: "doc.text")
                            .lineLimit(1)
                        Text(" – Edit")
                            .foregroundColor(
                                Color.Subconscious.secondaryText
                            )
                    }
                case .query(let text):
                    HStack(spacing: 0) {
                        Label(text, systemImage: "magnifyingglass")
                            .lineLimit(1)
                        Text(" – Search")
                            .foregroundColor(
                                Color.Subconscious.secondaryText
                            )
                    }
                case .create(let text):
                    HStack(spacing: 0) {
                        Label(text, systemImage: "plus.circle")
                            .lineLimit(1)
                        Text(" – Create")
                            .foregroundColor(
                                Color.Subconscious.secondaryText
                            )
                    }
                }
            }
            .contentShape(Rectangle())
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
}

struct SuggestionRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SuggestionRowView(
                suggestion: Suggestion.query("Search term")
            )
            SuggestionRowView(
                suggestion: Suggestion.query("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
            )
            SuggestionRowView(
                suggestion: Suggestion.entry(
                    url: URL(fileURLWithPath: "example.subtext"),
                    title: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
                )
            )
            SuggestionRowView(
                suggestion: Suggestion.create("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
            )
        }
    }
}
