//
//  RenameSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSearchView: View {
    var current: EntryLink?
    var placeholder: String = "Enter name for idea"
    var suggestions: [RenameSuggestion]
    @Binding var text: String
    var onCancel: () -> Void
    var onSelect: (RenameSuggestion) -> Void

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
                autofocus: true
            )
            .submitLabel(.done)
            .padding(.bottom, AppTheme.padding)
            .padding(.horizontal, AppTheme.padding)
            List(suggestions) { suggestion in
                Button(
                    action: {
                        onSelect(suggestion)
                    },
                    label: {
                        RenameSuggestionLabelView(suggestion: suggestion)
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
            current: EntryLink(title: "Flop")!,
            suggestions: [
                .move(
                    from: EntryLink(
                        slug: Slug("flop")!,
                        title: "Flop"
                    ),
                    to: EntryLink(
                        slug: Slug("zoom")!,
                        title: "Zoom"
                    )
                ),
                .merge(
                    parent: EntryLink(
                        slug: Slug("card-wars")!,
                        title: "Card wars"
                    ),
                    child: EntryLink(
                        slug: Slug("floop")!,
                        title: "Floop"
                    )
                )
            ],
            text: .constant(""),
            onCancel: {},
            onSelect: { suggestion in
                
            }
        )
    }
}
