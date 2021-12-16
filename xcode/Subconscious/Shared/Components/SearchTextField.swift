//
//  SearchTextField.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct SearchTextField: View {
    var placeholder: String
    @Binding var text: String
    var autofocus: Bool = false
    // The ergonomics of SwiftUI focus management make it difficult to
    // track in our store. Accepting this limitation for now and
    // staying on the SwiftUI happy path for now.
    // See https://developer.apple.com/documentation/swiftui/view/focused(_:).
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        TextField("Search or create...", text: $text)
            .textInputAutocapitalization(.sentences)
            .focused($isSearchFocused)
            .textFieldStyle(.plain)
            .modifier(RoundedTextFieldViewModifier())
            .onAppear {
                if autofocus {
                    isSearchFocused = true
                }
            }
            .onDisappear {
                isSearchFocused = false
            }
    }
}

struct SearchTextField_Previews: PreviewProvider {
    static var previews: some View {
        SearchTextField(
            placeholder: "Search or create...",
            text: .constant("")
        )
    }
}
