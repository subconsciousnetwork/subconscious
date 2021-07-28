//
//  ActionSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/5/21.
//

import SwiftUI

//  MARK: Row View
struct ActionSuggestionView: View, Equatable {
    var suggestion: ActionSuggestion

    var body: some View {
        Group {
            switch suggestion {
            case .edit(_, let title):
                HStack(spacing: 0) {
                    IconLabelRowView(
                        title: title,
                        image: Image(systemName: "doc.text")
                    )

                    Text(" – Edit").foregroundColor(Constants.Color.secondaryText)
                }
            case .create(let title):
                HStack(spacing: 0) {
                    IconLabelRowView(
                        title: title,
                        image: Image(systemName: "doc.badge.plus")
                    )

                    Text(" – Create").foregroundColor(Constants.Color.secondaryText)
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
            ActionSuggestionView(
                suggestion: ActionSuggestion.create("Search term")
            )
            ActionSuggestionView(
                suggestion: ActionSuggestion.create("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
            )
            ActionSuggestionView(
                suggestion: ActionSuggestion.edit(
                    url: URL(fileURLWithPath: "example.subtext"),
                    title: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
                )
            )
            ActionSuggestionView(
                suggestion: ActionSuggestion.create("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
            )
        }
    }
}
