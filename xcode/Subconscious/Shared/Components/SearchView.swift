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
    var suggestionHeight: CGFloat = 56
    @Binding var text: String
    @Binding var focus: AppFocus?
    @Binding var suggestions: [Suggestion]
    /// Select suggestion
    var onSelect: (Suggestion) -> Void
    /// Commit via keyboard
    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    /// Calculate maxHeight given number of suggestions.
    /// This allows us to adapt the height of the modal to the
    /// suggestions that are returned.
    private func calcMaxHeight() -> CGFloat {
        CGFloat.minimum(
            suggestionHeight * CGFloat(suggestions.count),
            suggestionHeight * 6
        )
    }

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
                    self.onSubmit(text)
                }
                Button(
                    action: onCancel,
                    label: {
                        Text("Cancel")
                    }
                )
            }
            .frame(height: AppTheme.unit * 10)
            .padding(AppTheme.tightPadding)
            List(suggestions) { suggestion in
                Button(
                    action: {
                        onSelect(suggestion)
                    },
                    label: {
                        SuggestionLabelView(suggestion: suggestion)
                    }
                )
                .modifier(
                    SuggestionViewModifier(
                        // Set suggestion height explicitly so we can
                        // rely on it for our search modal height
                        // calculations.
                        // 2022-02-17 Gordon Brander
                        height: suggestionHeight
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
            .frame(maxHeight: calcMaxHeight())
            .listStyle(.plain)
            .padding(.bottom, AppTheme.tightPadding)
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
            onSelect: { suggestion in },
            onSubmit: { query in },
            onCancel: {}
        )
    }
}
