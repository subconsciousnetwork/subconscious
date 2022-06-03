//
//  RenameSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSearchView: View {
    /// Link of the note we are renaming
    var link: EntryLink?
    var placeholder: String = "Enter name for idea"
    var suggestions: [RenameSuggestion]
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    var onCancel: () -> Void
    var onSelect: (EntryLink?, EntryLink) -> Void

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
            .padding(.bottom, AppTheme.padding)
            .padding(.horizontal, AppTheme.padding)
            List(suggestions) { suggestion in
                Button(
                    action: {
                        onSelect(
                            link,
                            EntryLink(suggestion)
                        )
                    },
                    label: {
                        RenameSuggestionLabelView(suggestion: suggestion)
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

struct RenameSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RenameSearchView(
            link: EntryLink(title: "Floop")!,
            suggestions: [
                .rename(
                    EntryLink(
                        slug: Slug("floop")!,
                        title: "Floop"
                    )
                ),
                .merge(
                    EntryLink(
                        slug: Slug("card-wars")!,
                        title: "Card wars"
                    )
                )
            ],
            text: .constant(""),
            focus: .constant(nil),
            onCancel: {},
            onSelect: { slug, suggestion in
                
            }
        )
    }
}
