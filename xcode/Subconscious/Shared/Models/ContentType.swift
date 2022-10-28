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
}

extension ContentType {
    var ext: String {
        switch self {
        case .subtext:
            return "subtext"
        case .memo:
            return "memo"
        case .story:
            return "story"
        }
    }
}

