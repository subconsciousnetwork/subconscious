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

    var body: some View {
        TextField("Search or create...", text: $text)
            .textInputAutocapitalization(.sentences)
            .textFieldStyle(.plain)
            .modifier(RoundedTextFieldViewModifier())
            .frame(height: AppTheme.unit * 9)
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
