//
//  ResultsList.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI
import Combine

//  MARK: Result model
struct ThreadResult: Identifiable, Codable {
    var id: String {
        "thread/\(text.hash)"
    }
    var text: String
}

struct QueryResult: Identifiable, Codable {
    var id: String {
        "query/\(text.hash)"
    }
    var text: String
}

struct CreateResult: Identifiable, Codable {
    var id: String {
        "create/\(text.hash)"
    }
    var text: String
}

enum Result {
    case thread(ThreadResult)
    case query(QueryResult)
    case create(CreateResult)
}

extension Result: Identifiable {
    var id: String {
        switch self {
        case .thread(let block):
            return block.id
        case .query(let block):
            return block.id
        case .create(let block):
            return block.id
        }
    }
}

extension Result {
    var text: String {
        switch self {
        case .thread(let block):
            return block.text
        case .query(let block):
            return block.text
        case .create:
            return ""
        }
    }
}

//  MARK: Row View
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
