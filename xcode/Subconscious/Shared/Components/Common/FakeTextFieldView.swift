//
//  FakeTextField.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/8/21.
//

import SwiftUI

struct FakeTextFieldView: View {
    var text: String
    
    var body: some View {
        HStack {
            Text(text)
            Spacer()
        }
        .foregroundColor(Color.Sub.secondaryText)
        .frame(
            width: .infinity,
            height: 36,
            alignment: .leading
        )
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.Sub.separator, lineWidth: 1)
        )
    }
}

struct FakeTextField_Previews: PreviewProvider {
    static var previews: some View {
        FakeTextFieldView(
            text: "Reply"
        )
    }
}
