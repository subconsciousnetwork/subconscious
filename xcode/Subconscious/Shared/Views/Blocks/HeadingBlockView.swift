//
//  TitleBlockView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/6/21.
//

import SwiftUI

struct HeadingBlockView: View {
    var block: HeadingBlock

    var body: some View {
        Text(block.text)
            .font(.body)
            .bold()
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

struct HeadingBlockView_Previews: PreviewProvider {
    static var previews: some View {
        HeadingBlockView(
            block: HeadingBlock(
                text: "Foo"
            )
        )
    }
}
