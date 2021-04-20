//
//  BlockView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI

/// Provides a single concrete view for all kinds of block
struct BlockView: View {
    var block: Block
    
    var body: some View {
        Group {
            switch block {
            case .text(let block):
                TextBlockView(block: block)
                    .lineLimit(nil)
            case .heading(let block):
                HeadingBlockView(block: block)
                    .lineLimit(nil)
            }
        }
    }
}

struct BlockView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BlockView(
                block: Block.heading(
                    HeadingBlock(
                        text: "Hello, world!"
                    )
                )
            )
            BlockView(
                block: Block.text(
                    TextBlock(
                        text: "Hello, world!"
                    )
                )
            )
        }
    }
}
