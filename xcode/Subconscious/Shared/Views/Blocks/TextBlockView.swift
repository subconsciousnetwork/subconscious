//
//  TextBlockView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/6/21.
//

import SwiftUI

struct TextBlockView: View {
    var block: TextBlock

    var body: some View {
        Text(block.text)
            .font(.body)
            .padding(.bottom, 8)
            .padding(.top, 8)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }
}

struct TextBlockView_Previews: PreviewProvider {
    static var previews: some View {
        TextBlockView(
            block: TextBlock(
                text: "Hello, world"
            )
        )
    }
}
