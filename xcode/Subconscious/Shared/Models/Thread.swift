//
//  Thread.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//
import Foundation

struct Thread: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var blocks: [Block]
}

extension Thread {
    init(markup: String = "", title: String = "", id: UUID = UUID()) {
        self.id = id
        self.title = title
        self.blocks = markup
            .split(whereSeparator: \.isNewline)
            .map { subsequence in
                Block.text(TextBlock(text: String(subsequence)))
            }
    }
    
    func toMarkup() -> String {
        return self.blocks
            .map { block in
                switch block {
                case .text(let block):
                    return block.text
                case .heading(let block):
                    return block.text
                }
            }
            .joined(separator: "\n")
    }
}
