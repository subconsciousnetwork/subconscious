//
//  FakeRoundedTextView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct FakeRoundedTextView: View {
    var placeholder: String
    var action: () -> Void
    var body: some View {
        Button(
            action: action,
            label: {
                VStack {
                    HStack {
                        Text(
                            placeholder
                        ).foregroundColor(
                            Color.placeholderText
                        )
                        Spacer()
                    }
                    Spacer()
                }
            }
        ).frame(
            // Space for two lines
            height: AppTheme.lineHeight * 2
        ).modifier(
            RoundedTextViewModifier()
        )
    }
}

struct FakeRoundedTextView_Previews: PreviewProvider {
    static var previews: some View {
        FakeRoundedTextView(
            placeholder: "Search or create...",
            action: {}
        )
    }
}
