//
//  RenameSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSearchView: View {
    /// Slug of the note we are renaming
    var slug: Slug?
    var placeholder: String = "Enter name for idea"
    var suggestions: [Suggestion]
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    var onCancel: () -> Void
    var onCommit: (Slug?, Slug?) -> Void

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
                onCommit(slug, text.toSlug())
            }
            .padding(.bottom, AppTheme.padding)
            .padding(.horizontal, AppTheme.padding)
            List(suggestions) { suggestion in
                Button(
                    action: {
                        withAnimation(
                            .easeOutCubic(duration: Duration.keyboard)
                        ) {
                            onCommit(slug, suggestion.stub.slug)
                        }
                    },
                    label: {
                        RenameSuggestionLabelView(suggestion: suggestion)
                    }
                )
                .modifier(
                    SuggestionViewModifier(
                        insets: EdgeInsets(
                            top: AppTheme.unit2,
                            leading: AppTheme.padding,
                            bottom: AppTheme.unit2,
                            trailing: AppTheme.padding
                        )
                    )
                )
            }
            .listStyle(.plain)
        }
        .background(Color.background)
    }
}

struct RenameSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RenameSearchView(
            slug: Slug("floop")!,
            suggestions: [
                .search(
                    EntryLink(
                        slug: Slug("floop")!,
                        title: "Floop"
                    )
                ),
                .entry(
                    EntryLink(
                        slug: Slug("card-wars")!,
                        title: "Card wars"
                    )
                )
            ],
            text: .constant(""),
            focus: .constant(nil),
            onCancel: {},
            onCommit: { current, next in }
        )
    }
}
