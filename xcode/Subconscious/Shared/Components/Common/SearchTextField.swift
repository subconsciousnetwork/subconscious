//
//  SearchTextField.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct SearchTextField: View {
    @FocusState private var viewFocus: AppFocus?
    var placeholder: String
    @Binding var text: String
    @Binding var focus: AppFocus?
    var field: AppFocus

    var body: some View {
        TextField(placeholder, text: $text)
            .focused($viewFocus, equals: field)
            // Replace changes to local focus onto external
            // focus binding.
            .onChange(of: self.viewFocus) { value in
                // Check before setting to prevent feedback loop
                if self.focus != value {
                    self.focus = value
                }
            }
            // Replay changes to focus in external focus binding
            // onto local focus state.
            //
            // FIXME: this is not firing when focus changes
            // At the moment, we can work around by setting focus via onAppear
            // but we need to figure out why onChange is not replaying our
            // change to focus to focusState.
            // onAppear can be used to manually set focusState from view.
            // However, this does not always work (e.g. in sheets).
            // We need a general solution.
            // 2021-01-05 Gordon Brander
            .onChange(of: self.focus) { value in
                // Check before setting to prevent feedback loop
                if self.viewFocus != value {
                    self.viewFocus = value
                }
            }
            .onAppear {
                self.viewFocus = self.focus
            }
            .modifier(RoundedTextFieldViewModifier())
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
