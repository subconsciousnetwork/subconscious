//
//  FakeRoundedTextView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct FakeRoundedTextView: View {
    var action: () -> Void
    var placeholder: String
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
            action: {},
            placeholder: "Search or create..."
        )
    }
}
