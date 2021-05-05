//
//  ResultsList.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI
import Combine

//  MARK: Results View
/// A single list for ranked results of multiple kinds
struct ResultsView: View {
    var results: [Result]
    let send: (AppAction) -> Void
    
    var body: some View {
        List(results) { result in
            Button(action: {
                send(.query(result.text))
            }) {
                ResultRowView(result: result)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(
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
            ],
            send:  { query in }
        )
    }
}
