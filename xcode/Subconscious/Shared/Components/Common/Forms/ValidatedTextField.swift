//
//  ValidatedTextField.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/7/23.
//

import SwiftUI
import Combine

/// A text field that comes with help text and a validation flag
struct ValidatedTextField: View {
    var placeholder: String
    @Binding var text: String
    var onFocusChanged: ((Bool) -> Void)?
    var caption: String
    var hasError: Bool = false
    @FocusState var focused: Bool
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            HStack {
                TextField(
                    placeholder,
                    text: $text
                )
                .focused($focused)
                .overlay(alignment: .trailing) {
                    VStack {
                        Image(systemName: "exclamationmark.circle")
                            .frame(width: 24, height: 22)
                            .padding(.horizontal, 8)
                            .foregroundColor(.red)
                            .background(Color.clear)
                    }
                    .padding(.trailing, 1)
                    .opacity(hasError ? 1 : 0)
                    .animation(.default, value: hasError)
                }
                // This works but it's incredibly chatty on every keystroke
                .onReceive(Just(focused)) { focused in
                    onFocusChanged?(focused)
                }
            }
            Text(caption)
                .foregroundColor(
                    hasError ? Color.red : Color.secondary
                )
                .animation(.default, value: hasError)
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
                hasError: true
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
                hasError: true
            )
            .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
}
