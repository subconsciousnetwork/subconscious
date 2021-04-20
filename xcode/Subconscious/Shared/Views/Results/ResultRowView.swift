//
//  ResultRow.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI

struct ResultRowView: View {
    var result: Result

    var body: some View {
        switch result {
        case .thread(let result):
            Label(result.text, systemImage: "doc.text")
                .lineLimit(1)
        case .query(let result):
            Label(result.text, systemImage: "magnifyingglass")
                .lineLimit(1)
        case .create(let result):
            Label("New: \(result.text)", systemImage: "plus.circle")
                .lineLimit(1)
        }
    }
}

struct ResultRow_Previews: PreviewProvider {
    static var previews: some View {
        ResultRowView(
            result: Result.thread(
                ThreadResult(
                    text: "If you have 70 notecards, you have a movie and this title goes on for far too long it just keeps going and going so we should truncate it"
                )
            )
        )
    }
}
