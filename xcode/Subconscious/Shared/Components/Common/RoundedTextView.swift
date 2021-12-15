//
//  RoundedTextView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct RoundedTextView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    var placeholder: String

    var body: some View {
        PlaceholderTextView(
            text: $text,
            isFocused: $isFocused,
            placeholder: placeholder,
            font: UIFont.appText
        ).frame(
            // Space for two lines
            height: AppTheme.lineHeight * 2
        ).modifier(
            RoundedTextViewModifier()
        )
    }
}
