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
    var onCommit: (String) -> Void

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
            .padding()
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        Button(
                            action: {
                                withAnimation(
                                    .easeOut(duration: Duration.fast)
                                ) {
                                    onCommit(suggestion.stub.slug)
                                }
                            }
                        ) {
                            LinkSuggestionLabelView(
                                suggestion: suggestion
                            )
                        }.buttonStyle(RowButtonStyle())
                    }
                }
            }
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
