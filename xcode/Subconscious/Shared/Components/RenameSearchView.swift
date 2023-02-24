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
            current: EntryLink(
                address: MemoAddress.local(
                    Slug("loomings")!
                ),
                title: "Loomings"
            ),
            suggestions: [
                .move(
                    from: EntryLink(
                        address: MemoAddress.public(
                            Slashlink("@here/loomings")!
                        ),
                        title: "Loomings"
                    ),
                    to: EntryLink(
                        address: MemoAddress.public(
                            Slashlink("@here/the-lee-shore")!
                        ),
                        title: "The Lee Shore"
                    )
                ),
                .merge(
                    parent: EntryLink(
                        address: MemoAddress.public(
                            Slashlink("@here/breakfast")!
                        ),
                        title: "Breakfast"
                    ),
                    child: EntryLink(
                        address: MemoAddress.public(
                            Slashlink("@here/the-street")!
                        ),
                        title: "The Street"
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
