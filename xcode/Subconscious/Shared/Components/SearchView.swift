//
//  SearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct SearchView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var suggestions: [Suggestion]
    var placeholder: String
    var commit: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            RoundedTextView(
                text: $text,
                isFocused: $isFocused,
                placeholder: placeholder
            )
            ForEach(suggestions, id: \.self) { suggestion in
                Button(
                    action: {
                        commit(
                            suggestion.stub.title,
                            suggestion.stub.slug
                        )
                    }
                ) {
                    SuggestionLabelView(
                        suggestion: suggestion
                    )
                }
            }
            Spacer()
        }.padding(
        ).background(
            Color.background
        )
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            text: .constant(""),
            isFocused: .constant(true),
            suggestions: .constant([]),
            placeholder: "",
            commit: { title, slug in
            }
        )
    }
}
