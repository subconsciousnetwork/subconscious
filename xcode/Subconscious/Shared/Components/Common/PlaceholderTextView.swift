//
//  PlaceholderTextView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

/// Wrapper for TextViewRepresentable that includes placeholder functionality
struct PlaceholderTextView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    var placeholder: String
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(
                        placeholder
                    ).font(
                        Font(font)
                    ).foregroundColor(
                        Color.placeholderText
                    ).opacity(
                        text == "" ? 1 : 0
                    )
                    Spacer()
                }
                Spacer()
            }
            TextViewRepresentable(
                text: $text,
                isFocused: $isFocused,
                font: font
            )
        }
    }
}
