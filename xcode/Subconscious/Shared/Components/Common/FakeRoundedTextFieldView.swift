//
//  FakeRoundedTextFieldView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct FakeRoundedTextFieldView: View {
    var placeholder: String
    var body: some View {
        HStack {
            Text(placeholder)
                .foregroundColor(Color.placeholderText)
            Spacer()
        }.modifier(RoundedTextFieldViewModifier())
    }
}

struct FakeRoundedTextFieldView_Previews: PreviewProvider {
    static var previews: some View {
        FakeRoundedTextFieldView(
            placeholder: "Search or create..."
        )
    }
}
