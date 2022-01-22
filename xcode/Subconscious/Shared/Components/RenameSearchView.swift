//
//  RenameSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSearchView: View {
    /// Slug of the note we are renaming
    var slug: String?
    var placeholder: String = "Enter name for idea"
    var suggestions: [Suggestion]
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    var onCancel: () -> Void
    var onCommit: (Slug?, Slug) -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavigationToolbar(
                principal: {
                    Text("Rename")
                },
                leading: {
                    Button(
                        action: onCancel
                    ) {
                        Text("Cancel")
                    }
                    .buttonStyle(.plain)
                    .lineLimit(1)
                },
                trailing: {
                    EmptyView()
                }
            )
            .padding()
            SearchTextField(
                placeholder: placeholder,
                text: $text,
                focus: $focus,
                field: .rename
            )
            .submitLabel(.done)
            .onSubmit {
                // On submit, slugify contents of searchfield
                // and commit.
                onCommit(slug, text.slugify())
            }
            .padding(.bottom)
            .padding(.horizontal)
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
                                        slug,
                                        suggestion.stub.slug
                                    )
                                }
                            }
                        ) {
                            RenameSuggestionLabelView(
                                suggestion: suggestion
                            )
                        }.buttonStyle(RowButtonStyle())
                    }
                }
            }
        }
        .background(Color.background)
    }
}

struct RenameSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RenameSearchView(
            slug: "floop",
            suggestions: [
                .search(EntryLink(title: "Floop")),
                .entry(EntryLink(title: "Card wars"))
            ],
            text: .constant(""),
            focus: .constant(nil),
            onCancel: {},
            onCommit: { current, next in }
        )
    }
}
