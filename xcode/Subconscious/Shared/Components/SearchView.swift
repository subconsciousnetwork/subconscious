//
//  SearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct SearchView: View {
    @Binding var text: String
    @Binding var suggestions: [Suggestion]
    var placeholder: String
    var onCommit: (String, String?) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SearchTextField(
                    placeholder: "Search or create...",
                    text: $text
                )
                .submitLabel(.go)
                .onSubmit {
                    withAnimation(
                        .easeOut(duration: Duration.fast)
                    ) {
                        onCommit(
                            text,
                            nil
                        )
                    }
                }
                Button(
                    action: onCancel,
                    label: {
                        Text("Cancel")
                    }
                )
            }
            .frame(height: AppTheme.unit * 10)
            .padding()
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(
                            action: {
                                withAnimation(
                                    .easeOut(duration: Duration.fast)
                                ) {
                                    onCommit(
                                        suggestion.stub.title,
                                        suggestion.stub.slug
                                    )
                                }
                            }
                        ) {
                            SuggestionLabelView(
                                suggestion: suggestion
                            )
                        }.buttonStyle(RowButtonStyle())
                    }.background(Color.background)
                }
            }
        }.background(Color.background)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            text: .constant(""),
            suggestions: .constant([]),
            placeholder: "",
            onCommit: { title, slug in
            },
            onCancel: {}
        )
    }
}
