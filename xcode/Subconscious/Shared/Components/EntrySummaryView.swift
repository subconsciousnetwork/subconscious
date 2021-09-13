//
//  EntryListView.swift
//  EntryListView
//
//  Created by Gordon Brander on 9/11/21.
//

import SwiftUI

/// Shows a summary of an entry that can be displayed in a list context.
struct EntrySummaryView: View, Equatable {
    struct Model: Equatable {
        var dom: Subtext2

        init(dom subtext: Subtext2) {
            self.dom = subtext.truncate()
        }

        init(markup: String) {
            self.dom = Subtext2(markup: markup).truncate()
        }
    }

    var state: Model

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(state.dom.children) { block in
                Text(block.renderPlain())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .contentShape(Rectangle())
           }
        }
    }
}

struct EntrySummaryView_Previews: PreviewProvider {
    static var previews: some View {
        EntrySummaryView(
            state: .init(markup: "")
        )
    }
}
