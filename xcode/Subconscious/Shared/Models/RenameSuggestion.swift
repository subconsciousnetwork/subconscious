//
//  RenameSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import Foundation

enum RenameSuggestion:
    Hashable,
    Equatable,
    Identifiable,
    CustomStringConvertible
{
    /// Move entry from one location to another, also updating title
    case move(from: Slashlink, to: Slashlink)
    /// Merge child into parent
    case merge(parent: Slashlink, child: Slashlink)

    var id: String {
        switch self {
        case let .move(from, to):
            return "move/\(from.id)/\(to.id)"
        case let .merge(parent, child):
            return "merge/\(parent.id)/\(child.id)"
        }
    }

    var description: String {
        switch self {
        case let .move(_, to):
            return to.slug.description
        case let .merge(parent, _):
            return parent.slug.description
        }
    }
}
