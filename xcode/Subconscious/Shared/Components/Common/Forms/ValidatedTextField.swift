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
    var caption: String
    var isValid: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            HStack {
                TextField(
                    placeholder,
                    text: $text
                )
                .overlay(alignment: .trailing) {
                    VStack {
                        Image(systemName: "exclamationmark.circle")
                            .frame(width: 24, height: 22)
                            .padding(.horizontal, 8)
                            .foregroundColor(.red)
                            .background(Color.clear)
                    }
                    .padding(.trailing, 1)
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
        VStack {
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant(""),
                caption: "Lowercase letters and numbers only."
            )
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant(""),
                caption: "Lowercase letters and numbers only.",
                isValid: false
            )
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant(""),
                caption: "Lowercase letters and numbers only."
            )
            .textFieldStyle(.roundedBorder)
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant("A very long run of text to test how this interacts with the icon"),
                caption: "Lowercase letters and numbers only.",
                isValid: false
            )
            .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
}
