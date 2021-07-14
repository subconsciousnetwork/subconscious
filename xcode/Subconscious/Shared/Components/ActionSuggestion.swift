//
//  ActionSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/5/21.
//

import SwiftUI

enum ActionSuggestion: Equatable, Hashable {
    case edit(url: URL, title: String)
    case create(_ text: String)
}

extension ActionSuggestion: Identifiable {
    var id: String {
        switch self {
        case .edit(_, let title):
            return "entry/\(title.hash)"
        case .create(let text):
            return "create/\(text.hash)"
        }
    }
}

extension ActionSuggestion: CustomStringConvertible {
    var description: String {
        switch self {
        case .edit(_, let title):
            return title
        case .create(let text):
            return text
        }
    }
}

//  MARK: Row View
struct SuggestionRowView: View, Equatable {
    var suggestion: ActionSuggestion

    var body: some View {
        Group {
            switch suggestion {
            case .edit(_, let title):
                HStack(spacing: 0) {
                    Label(
                        title,
                        systemImage: "doc.text"
                    )
                    .lineLimit(1)
                    .foregroundColor(.Sub.text)

                    Text(" – Edit").foregroundColor(
                        Color.Sub.secondaryText
                    )
                }
            case .create(let text):
                HStack(spacing: 0) {
                    Label(
                        text,
                        systemImage: "doc.badge.plus"
                    )
                    .foregroundColor(.Sub.text)
                    .lineLimit(1)

                    Text(" – Create").foregroundColor(
                        Color.Sub.secondaryText
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

struct SuggestionRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SuggestionRowView(
                suggestion: ActionSuggestion.create("Search term")
            )
            SuggestionRowView(
                suggestion: ActionSuggestion.create("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
            )
            SuggestionRowView(
                suggestion: ActionSuggestion.edit(
                    url: URL(fileURLWithPath: "example.subtext"),
                    title: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
                )
            )
            SuggestionRowView(
                suggestion: ActionSuggestion.create("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
            )
        }
    }
}
