//
//  ValidatedTextField.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/7/23.
//

import SwiftUI

/// A text field that comes with help text and a validation flag
struct ValidatedTextField: View {
    var placeholder: String
    @Binding var text: String
    var caption: String = ""
    var isValid: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            HStack {
                TextField(
                    placeholder,
                    text: $text
                )
                if !isValid {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                        .opacity(isValid ? 0 : 1)
                        .animation(.default, value: isValid)
                }
            }
            Text(caption)
                .foregroundColor(
                    isValid ? Color.secondary : Color.red
                )
                .animation(.default, value: isValid)
                .font(.caption)
        }
    }
}

struct ValidatedTextField_Previews: PreviewProvider {
    static var previews: some View {
        ValidatedTextField(
            placeholder: "nickname",
            text: .constant(""),
            caption: "Lowercase letters and numbers only."
        )
    }
}
