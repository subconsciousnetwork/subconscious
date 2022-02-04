//
//  LinkSearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct LinkSearchView: View {
    var placeholder: String
    var suggestions: Suggestions
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    var onCancel: () -> Void
    var onCommit: (Slug) -> Void

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
            .padding(AppTheme.padding)
            List {
                Section(header: Text("Entries")) {
                    ForEach(suggestions.entries) { suggestion in
                        Button(
                            action: {
                                withAnimation(
                                    .easeOutCubic(duration: Duration.keyboard)
                                ) {
                                    onCommit(suggestion.slug)
                                }
                            },
                            label: {
                                StubLabelView(
                                    icon: Image(systemName: "doc"),
                                    title: suggestion.slug.description,
                                    subtitle: #"Link to "\#(suggestion.title)""#
                                )
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
                }
            }
            .listStyle(.plain)
        }.background(Color.background)
    }
}

struct LinkSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LinkSearchView(
            placeholder: "Search or create...",
            suggestions: .empty,
            text: .constant(""),
            focus: .constant(nil),
            onCancel: {},
            onCommit: { slug in }
        )
    }
}
