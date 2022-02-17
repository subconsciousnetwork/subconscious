//
//  LinkSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct LinkSearchView: View {
    var placeholder: String
    var suggestions: [Suggestion]
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    var onCancel: () -> Void
    var onCommit: (Slug) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SearchTextField(
                    placeholder: "Search links",
                    text: $text,
                    focus: $focus,
                    field: .linkSearch
                )
                Button(
                    action: onCancel,
                    label: {
                        Text("Cancel")
                    }
                ).buttonStyle(.plain)
            }
            .frame(height: AppTheme.unit * 10)
            .padding(AppTheme.padding)
            List(suggestions) { suggestion in
                Button(
                    action: {
                        withAnimation(
                            .easeOutCubic(
                                duration: Duration.keyboard
                            )
                        ) {
                            onCommit(suggestion.slug)
                        }
                    },
                    label: {
                        LinkSuggestionLabelView(suggestion: suggestion)
                    }
                )
                .modifier(SuggestionViewModifier())
            }
            .listStyle(.plain)
        }.background(Color.background)
    }
}

struct LinkSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LinkSearchView(
            placeholder: "Search or create...",
            suggestions: [],
            text: .constant(""),
            focus: .constant(nil),
            onCancel: {},
            onCommit: { slug in }
        )
    }
}
