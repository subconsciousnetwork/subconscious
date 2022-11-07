//
//  ContentType.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/15/22.
//

import Foundation

enum ContentType: String {
    case subtext = "text/subtext"
    case memo = "application/memo+json"
    case story = "application/story+json"
    case text = "text/plain"
}

extension ContentType {
    var fileExtension: String {
        switch self {
        case .subtext:
            return "subtext"
        case .memo:
            return "memo"
        case .story:
            return "story"
        case .text:
            return "txt"
        }
    }
}

