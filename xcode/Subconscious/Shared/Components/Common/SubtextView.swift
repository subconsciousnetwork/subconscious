//
//  MemoView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/5/23.
//

import SwiftUI

struct SubtextView: View {
    var subtext: Subtext
    var renderer: SubtextAttributedStringRenderer = SubtextAttributedStringRenderer()

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(subtext.blocks, id: \.self) { block in
                Text(renderer.render(block.body().description))
            }
        }
    }
}

struct SubtextView_Previews: PreviewProvider {
    static var previews: some View {
        SubtextView(
            subtext: Subtext(
                markup: """
                Say not, "I have found _the_ truth," but rather, "I have found a truth."

                Say not, "I have found the path of the soul." Say rather, "I have met the soul walking upon my path."

                For the soul walks upon all paths.

                The soul walks not upon a line, neither does it grow like a reed.

                The soul unfolds itself, like a lotus of countless petals.
                """
            ),
            renderer: SubtextAttributedStringRenderer()
        )
    }
}
