//
//  SearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct SearchView: View {
    var placeholder: String
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
                                    onCommit(
                                        suggestion.stub.slug,
                                        suggestion.stub.title
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
            placeholder: "",
            text: .constant(""),
            focus: .constant(nil),
            suggestions: .constant([]),
            onCommit: { slug, title in },
            onCancel: {}
        )
    }
}
