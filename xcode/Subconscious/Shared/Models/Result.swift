//
//  Result.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

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
