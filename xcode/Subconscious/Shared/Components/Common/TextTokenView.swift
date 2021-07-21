//
//  TextToken.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/6/21.
//

import SwiftUI

struct TextTokenView: View {
    var text: String

    var body: some View {
        Text(text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .foregroundColor(.Sub.buttonBackground)
            )
    }
}

struct TextTokenView_Previews: PreviewProvider {
    static var previews: some View {
        TextTokenView(text: "#log")
    }
}
