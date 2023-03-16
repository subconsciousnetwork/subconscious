//
//  RoundedTextFieldViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

/// Styles a view as if it is a rounded input field.
struct RoundedTextFieldViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.sentences)
            .textFieldStyle(.plain)
            .padding(.horizontal, Unit.three)
            .padding(.vertical, Unit.two)
            .background(Color.inputBackground)
            .cornerRadius(Unit.cornerRadius)
            .frame(height: Unit.unit * 9)
    }
}
