//
//  Block.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/7/21.
//
import Foundation

struct TextBlock: Identifiable, Codable {
    var id: UUID
    var text: String

    init(text: String) {
        self.id = UUID()
        self.text = text
    }
}

struct HeadingBlock: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String

    init(text: String) {
        self.id = UUID()
        self.text = text
    }
}

enum Block {
    case text(TextBlock)
    case heading(HeadingBlock)
}

extension Block: Identifiable {
    var id: UUID {
        switch self {
        case .text(let block):
            return block.id
        case .heading(let block):
            return block.id
        }
    }
}
