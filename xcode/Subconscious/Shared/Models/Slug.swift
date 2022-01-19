//
//  Slug.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/18/22.
//

import Foundation

/// A slug is a local path and ID for an entry
/// Currently this is just a typealias. In future we may give it a
/// distinct type.
typealias Slug = String


extension URL {
    /// Convert URL to slug
    func toSlug() -> Slug {
        self.deletingPathExtension().lastPathComponent
    }
}
