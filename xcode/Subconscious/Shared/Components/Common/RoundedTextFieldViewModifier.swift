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
            .padding(.horizontal, AppTheme.unit * 3)
            .padding(.vertical, AppTheme.unit * 2)
            .background(Color.inputBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .frame(height: AppTheme.unit * 9)
    }
}
