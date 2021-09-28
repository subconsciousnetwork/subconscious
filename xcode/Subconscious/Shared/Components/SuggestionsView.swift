//
//  Suggestions.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/16/21.
//

import SwiftUI

enum Suggestion: Hashable, CustomStringConvertible {
    case entry(String)
    case search(String)

    var description: String {
        switch self {
        case let .entry(string):
            return string
        case let .search(string):
            return string
        }
    }
}

struct SuggestionsView: View {
    var suggestions: [Suggestion]
    var action: (Suggestion) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(
                        action: {
                            self.action(suggestion)
                        },
                        label: {
                            VStack {
                                switch suggestion {
                                case .entry(let string):
                                    HStack {
                                        Image(
                                            systemName: "doc"
                                        ).frame(
                                            width: AppTheme.icon,
                                            height: AppTheme.icon
                                        ).foregroundColor(Color.icon)
                                        Text(string)
                                        Text("— Open").foregroundColor(
                                            Color.secondaryText
                                        )
                                        Spacer()
                                    }
                                    .padding(AppTheme.padding)
                                    .contentShape(Rectangle())
                                case .search(let string):
                                    HStack {
                                        Image(
                                            systemName: "magnifyingglass"
                                        ).frame(
                                            width: AppTheme.icon,
                                            height: AppTheme.icon
                                        ).foregroundColor(Color.icon)
                                        Text(string)
                                        Text("- Create").foregroundColor(
                                            Color.secondaryText
                                        )
                                        Spacer()
                                    }
                                    .padding(AppTheme.padding)
                                    .contentShape(Rectangle())

                                }
                            }
                            .lineLimit(1)
                        }
                    ).buttonStyle(RowButtonStyle())
                    Divider()
                }
            }
        }
        .background(Color.background)
        .transition(
            .offset(x: 0, y: 48)
            .combined(with: .opacity)
        )
    }
}

struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionsView(
            suggestions: [
                .search("El"),
                .entry("Elm discourages deeply nested records"),
                .entry("Elm a very long page title that should get truncated"),
                .entry("Elm app architecture"),
                .search("Elm"),
                .search("Elephant")
            ],
            action: { suggestion in }
        )
    }
}
