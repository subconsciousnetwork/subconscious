//
//  SearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct SearchView: View {
    var placeholder: String
    //  NOTE: suggestionHeight is title height plus subtitle height
    //  plus top and bottom padding.
    /// Row height is a fixed height we apply to suggestions in order
    /// to calculate the height of the `List` that contains them.
    /// This allows us to shrink the modal when only a few results are
    /// present.
    var suggestionHeight: CGFloat = (24 + 12 + 8 + 8)
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    @Binding var suggestions: [Suggestion]
    var onCommit: (Slug?, String) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SearchTextField(
                    placeholder: "Search or create...",
                    text: $text,
                    focus: $focus,
                    field: .search
                )
                .submitLabel(.go)
                .onSubmit {
                    withAnimation(
                        .easeOut(duration: Duration.fast)
                    ) {
                        onCommit(
                            text.slugify(),
                            text
                        )
                    }
                }
                Button(
                    action: onCancel,
                    label: {
                        Text("Cancel")
                    }
                ).buttonStyle(.plain)
            }
            .frame(height: AppTheme.unit * 10)
            .padding(AppTheme.tightPadding)
            List(suggestions) { suggestion in
                Button(
                    action: {
                        withAnimation(
                            .easeOutCubic(duration: Duration.keyboard)
                        ) {
                            onCommit(
                                suggestion.stub.slug,
                                suggestion.stub.title
                            )
                        }
                    },
                    label: {
                        SuggestionLabelView(suggestion: suggestion)
                    }
                )
                .frame(height: suggestionHeight)
                .modifier(
                    // Because we fix the height of the suggestions (see below)
                    // we do not set edge insets on the suggestion, as
                    // this is unneccessary and would increase the height
                    // of our suggestion (frame + inset), throwing off
                    // height calculations below.
                    // 2022-01-28 Gordon Brander
                    SuggestionViewModifier(
                        insets: EdgeInsets(
                            top: 0,
                            leading: AppTheme.tightPadding,
                            bottom: 0,
                            trailing: AppTheme.tightPadding
                        )
                    )
                )
            }
            // Fix the height of the scrollview based on the number of
            // elements present.
            //
            // This allows us to shrink the modal when there are only a
            // few elements to show.
            //
            // 2022-01-28 Gordon Brander
            .frame(
                maxHeight: AppTheme.tightPadding + CGFloat.minimum(
                    suggestionHeight * CGFloat(suggestions.count),
                    suggestionHeight * 6
                )
            )
            .listStyle(.plain)
        }
        .background(Color.background)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            placeholder: "",
            text: .constant(""),
            focus: .constant(nil),
            suggestions: .constant([]),
            onCommit: { slug, title in },
            onCancel: {}
        )
    }
}
