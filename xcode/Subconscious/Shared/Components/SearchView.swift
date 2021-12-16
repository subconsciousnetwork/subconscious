//
//  SearchView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct SearchView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var suggestions: [Suggestion]
    var placeholder: String
    var commit: (String, String) -> Void
    var cancel: () -> Void
    // The ergonomics of SwiftUI focus management make it difficult to
    // track in our store. Accepting this limitation for now and
    // staying on the SwiftUI happy path for now.
    // See https://developer.apple.com/documentation/swiftui/view/focused(_:).
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TextField("Search or create...", text: $text)
                    .textInputAutocapitalization(.sentences)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .modifier(RoundedTextFieldViewModifier())
                    .onAppear {
                        isSearchFocused = true
                    }
                Button(
                    action: cancel,
                    label: {
                        Text("Cancel")
                    }
                )
            }
            .frame(height: 36)
            .padding()
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(
                            action: {
                                commit(
                                    suggestion.stub.title,
                                    suggestion.stub.slug
                                )
                            }
                        ) {
                            SuggestionLabelView(
                                suggestion: suggestion
                            )
                        }
                        .buttonStyle(RowButtonStyle())
                    }
                    .background(Color.background)
                }
            }
        }
        .background(Color.background)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            text: .constant(""),
            isFocused: .constant(true),
            suggestions: .constant([]),
            placeholder: "",
            commit: { title, slug in
            },
            cancel: {}
        )
    }
}
