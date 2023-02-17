//
//  RenameSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSearchView: View {
    var current: EntryLink?
    var placeholder: String = "Enter name for note"
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
                autofocus: true,
                autofocusDelay: 0.5
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
            current: EntryLink(title: "Loomings", audience: .local)!,
            suggestions: [
                .move(
                    from: EntryLink(
                        title: "Loomings",
                        audience: .public
                    )!,
                    to: EntryLink(
                        title: "The Lee Shore",
                        audience: .public
                    )!
                ),
                .merge(
                    parent: EntryLink(
                        title: "Breakfast",
                        audience: .public
                    )!,
                    child: EntryLink(
                        title: "The Street",
                        audience: .public
                    )!
                )
            ],
            text: .constant(""),
            onCancel: {},
            onSelect: { suggestion in
                
            }
        )
    }
}
