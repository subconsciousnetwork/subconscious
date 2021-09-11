//
//  TranscludeView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/22/21.
//

import SwiftUI

struct TranscludeView: View, Equatable {
    struct Model: Equatable {
        var dom: Subtext2

        init(dom subtext: Subtext2) {
            self.dom = subtext.truncate()
        }
    }

    var state: Model

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(state.dom.children) { block in
                BlockView(block: block).equatable()
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
            state: .init(
                dom: Subtext2(
                    markup: """
                    # Namespaced wikilinks

                    In a federated system, you sometimes want to be able to reference some particular “truth”. The default wikilink should refer to my view of the world (my documents for this term). However, you also want to be able to reference Alice and Bob’s views of this term.

                    """
                )
            )
        )
    }
}
