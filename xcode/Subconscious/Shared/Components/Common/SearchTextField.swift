//
//  SearchTextField.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct SearchTextField: View {
    @FocusState private var focusState: Bool
    var placeholder: String
    @Binding var text: String
    var autofocus: Bool = false

    var body: some View {
        TextField(placeholder, text: $text)
            .focused($focusState)
            .task {
                if autofocus {
                    self.focusState = true
                }
            }
            .modifier(RoundedTextFieldViewModifier())
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
