//
//  ResultsList.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI

/// A single list for ranked results of multiple kinds
struct ResultListView: View {
    var results: [Result]
    let action: (Result) -> Void
    
    var body: some View {
        List(results) { result in
            Button(action: {
                action(result)
            }) {
                ResultRowView(result: result)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct ResultsList_Previews: PreviewProvider {
    static var previews: some View {
        ResultListView(
            results: [
                Result.thread(
                    ThreadResult(text: "If you have 70 notecards, you have a movie")
                ),
                Result.thread(
                    ThreadResult(text: "Tenuki")
                ),
                Result.query(
                    QueryResult(text: "Notecard")
                ),
                Result.create(
                    CreateResult(text: "Notecard")
                ),
            ]
        ) { query in }
    }
}
