//
//  Audience.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import Foundation

/// Model enumerating the possible audience/scopes for a piece of content.
/// Right now we only have two: fully public, or fully private
/// (and for now, local).
enum Audience: Hashable {
    case `public`
    case `private`
}
