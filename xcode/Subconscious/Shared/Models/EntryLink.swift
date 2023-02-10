//
//  EntryLink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

/// A EntryLink contains a slug, title, and linkable title.
/// Linkable title is a title that is reducible to the slug,
/// e.g. when used as a wikilink.
struct EntryLink:
    Hashable,
    Equatable,
    Identifiable,
    CustomStringConvertible,
    Codable
{
    /// Address for link
    let address: MemoAddress
    /// Actual title of link
    let title: String
    /// Linkable title that is always formattable to slug
    let linkableTitle: String
    
    init(address: MemoAddress, title: String) {
        self.address = address
        let title = Self.sanitizeTitle(title)
        self.title = title
        let titleSlug = Slug(formatting: title)
        self.linkableTitle = (
            titleSlug != address.slug ?
            Self.sanitizeTitle(address.slug.toTitle()) :
                title
        )
    }
    
    /// Construct an EntryLink from a string.
    /// Slug is generated for string using lossy approach.
    init?(title: String, audience: Audience) {
        let title = Self.sanitizeTitle(title)
        guard let address = title.toMemoAddress(audience: audience) else {
            return nil
        }
        self.title = title
        self.linkableTitle = title
        self.address = address
    }
    
    /// Construct an EntryLink from a slug.
    /// Title is generated using `slug.toTitle()`.
    init(address: MemoAddress) {
        self.address = address
        let title = Self.sanitizeTitle(address.slug.toTitle())
        self.title = title
        self.linkableTitle = title
    }
    
    var id: MemoAddress { address }
    var description: String { linkableTitle }
    
    static func sanitizeTitle(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(
                of: #"\s"#,
                with: " ",
                options: .regularExpression
            )
    }
}
