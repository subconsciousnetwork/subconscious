//
//  AppendLinkSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/1/2024.
//

enum AppendLinkSuggestion:
    Hashable,
    Equatable,
    Identifiable,
    CustomStringConvertible
{
    case append(address: Slashlink, target: Slashlink)
    var id: String {
        switch self {
        case let .append(address, target):
            return "append/\(address.id)/\(target.id)"
        }
    }

    var description: String {
        switch self {
        case let .append(address, target):
            return "append \(address.id) \(target.id)"
        }
    }
}
