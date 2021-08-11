//
//  TranscludeView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/22/21.
//

import SwiftUI

struct TranscludeView: View {
    var dom: [Subtext2.BlockNode]

    init(dom: [Subtext2.BlockNode]) {
        self.dom = Array(dom.prefix(2))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(dom) { block in
                BlockView(block: block)
            }
        }
        .foregroundColor(Constants.Color.text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(Constants.Color.secondaryBackground)
        .cornerRadius(CGFloat(Constants.Theme.cornerRadius))
    }
}

struct TranscludeView_Previews: PreviewProvider {
    static var previews: some View {
        TranscludeView(
            dom: Subtext2.parse(
                markup: """
                # Namespaced wikilinks

                In a federated system, you sometimes want to be able to reference some particular “truth”. The default wikilink should refer to my view of the world (my documents for this term). However, you also want to be able to reference Alice and Bob’s views of this term.

                """
            )
        )
    }
}
