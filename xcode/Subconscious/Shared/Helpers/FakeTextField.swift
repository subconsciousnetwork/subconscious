//
//  FakeTextField.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/8/21.
//

import SwiftUI

struct FakeTextField: View {
    var text: String
    
    var body: some View {
        HStack {
            Text(text)
            Spacer()
        }
        .foregroundColor(Color.Subconscious.secondaryText)
        .frame(
            width: .infinity,
            height: 36,
            alignment: .leading
        )
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.Subconscious.border, lineWidth: 1)
        )
    }
}

struct FakeTextField_Previews: PreviewProvider {
    static var previews: some View {
        FakeTextField(
            text: "Reply"
        )
    }
}
