//
//  BlockView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI

/// Provides a single concrete view for all kinds of block
struct BlockView: View, Equatable {
    var block: Subtext.Block
    
    var body: some View {
        Group {
            switch block {
            case .text(let block):
                TextBlockView(block: block)
            case .link(let block):
                LinkBlockView(block: block)
            case .list(let block):
                ListBlockView(block: block)
            case .heading(let block):
                HeadingBlockView(block: block)
            case .quote(let block):
                QuoteBlockView(block: block)
            case .blank:
                BlankBlockView()
            }
        }
    }
}

struct TextBlockView: View {
    var block: Subtext.TextBlock

    var body: some View {
        Text(block.value)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ListBlockView: View {
    var block: Subtext.ListBlock

    var body: some View {
        Text(block.value)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LinkBlockView: View {
    var block: Subtext.LinkBlock

    var body: some View {
        Text(block.value)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HeadingBlockView: View {
    var block: Subtext.HeadingBlock

    var body: some View {
        Text(block.value)
            .font(.body)
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuoteBlockView: View {
    var block: Subtext.QuoteBlock

    var body: some View {
        Text(block.value)
            .font(.body)
            .foregroundColor(Color.Sub.quotedText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BlankBlockView: View {
    var body: some View {
        Spacer().frame(height: 24)
    }
}
