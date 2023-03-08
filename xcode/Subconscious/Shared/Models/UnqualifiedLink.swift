//
//  UnqualifiedLink.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/10/23.
//

import Foundation

/// An unqualified link is a slug and title that does not have a known
/// audience. We use this for the editor, where a link can be to either
/// sphere content or a local draft, and it is not known which from the
/// text.
struct UnqualifiedLink: Hashable {
    var slashlink: Slashlink
    var title: String
}
