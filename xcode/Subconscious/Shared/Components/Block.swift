//
//  BlockView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI

/// Provides a single concrete view for all kinds of block
struct BlockView: View {
    var block: Subtext.Block
    
    var body: some View {
        Group {
            switch block.sigil {
            case .text:
                GenericBlockView(block: block)
            case .link:
                GenericBlockView(block: block)
            case .list:
                GenericBlockView(block: block)
            case .heading:
                HeadingBlockView(block: block)
            case .quote:
                QuoteBlockView(block: block)
            }
        }
    }
}

struct GenericBlockView: View {
    var block: Subtext.Block

    var body: some View {
        Text(block.value)
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

struct HeadingBlockView: View {
    var block: Subtext.Block

    var body: some View {
        Text(block.value)
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

struct QuoteBlockView: View {
    var block: Subtext.Block

    var body: some View {
        Text(block.value)
            .font(.body)
            .padding(.bottom, 8)
            .padding(.top, 8)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .foregroundColor(Color.Subconscious.quotedText)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }
}
