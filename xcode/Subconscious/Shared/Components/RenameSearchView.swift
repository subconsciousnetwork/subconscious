//
//  RenameSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSearchView: View {
    var placeholder: String = "Enter name for idea"
    var suggestions: [Suggestion]
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    var onCancel: () -> Void
    var onCommit: (String) -> Void

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
                                    onCommit(suggestion.stub.slug)
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
            suggestions: [
                .search(EntryLink(title: "Floop")),
                .entry(EntryLink(title: "Card wars"))
            ],
            text: .constant(""),
            focus: .constant(nil),
            onCancel: {},
            onCommit: { slug in }
        )
    }
}
