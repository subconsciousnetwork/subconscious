//
//  RoundedTextViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

/// Styles a view as if it is a rounded input field.
struct RoundedTextViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(
            Font(UIFont.appText)
        ).padding(
            .horizontal, AppTheme.unit * 3
        ).padding(
            .vertical, AppTheme.unit * 2
        ).background(
            Color.inputBackground
        ).cornerRadius(
            AppTheme.cornerRadius
        )
    }
}
