//
//  LinkSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct LinkSearchView: View {
    var placeholder: String
    var suggestions: [LinkSuggestion]
    @Binding var text: String
    var onCancel: () -> Void
    var onSelect: (LinkSuggestion) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DragHandleView()
                .padding(.top, AppTheme.tightPadding)
            HStack {
                SearchTextField(
                    placeholder: "Search links",
                    text: $text,
                    autofocus: true,
                    autofocusDelay: 0.5
                )
                Button(
                    action: onCancel,
                    label: {
                        Text("Cancel")
                    }
                )
            }
            .frame(height: AppTheme.unit * 10)
            .padding(.vertical, AppTheme.tightPadding)
            .padding(.horizontal, AppTheme.padding)
            List(suggestions) { suggestion in
                Button(
                    action: {
                        onSelect(suggestion)
                    },
                    label: {
                        LinkSuggestionLabelView(suggestion: suggestion)
                            .equatable()
                    }
                )
                .modifier(SuggestionViewModifier())
            }
            .listStyle(.plain)
        }
        .background(Color.background)
    }
}

struct LinkSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LinkSearchView(
            placeholder: "Search or create...",
            suggestions: [],
            text: .constant(""),
            onCancel: {},
            onSelect: { slug in }
        )
    }
}
