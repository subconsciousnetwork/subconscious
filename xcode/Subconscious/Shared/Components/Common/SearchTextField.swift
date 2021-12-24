//
//  SearchTextField.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct SearchTextField: View {
    @FocusState private var focusState: AppModel.Focus?
    var placeholder: String
    @Binding var text: String
    @Binding var focus: AppModel.Focus?
    var field: AppModel.Focus

    var body: some View {
        TextField(placeholder, text: $text)
            .modifier(RoundedTextFieldViewModifier())
            .focused($focusState, equals: field)
            // Replay changes to focus in external focus binding
            // onto local focus state.
            .onChange(of: focus) { value in
                self.focusState = value
            }
            // Replace changes to local focus onto external
            // focus binding.
            .onChange(of: focusState) { value in
                self.focus = value
            }
    }
}

struct SearchTextField_Previews: PreviewProvider {
    static var previews: some View {
        SearchTextField(
            placeholder: "Search or create...",
            text: .constant(""),
            focus: .constant(nil),
            field: .search
        )
    }
}
