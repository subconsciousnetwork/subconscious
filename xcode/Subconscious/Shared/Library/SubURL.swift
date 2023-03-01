//
//  SubURL.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import Foundation

extension UnqualifiedLink {
    init?(
        sluglike: String,
        title: String
    ) {
        guard let slug = Slug(sluglike) else {
            return nil
        }
        self.init(slug: slug, title: title)
    }

    /// Create a Subconscious app-specific URL encoding entry title and slug
    func encodeAsSubEntryURL() -> URL? {
        var components = URLComponents()
        components.scheme = "sub"
        components.host = "entry"
        components.path = self.slug.markup
        components.queryItems = [
            URLQueryItem(name: "title", value: self.title),
        ]
        return components.url
    }

    /// Construct entry link from sub entry URL
    static func decodefromSubEntryURL(_ url: URL) -> UnqualifiedLink? {
        guard url.scheme == "sub" && url.host == "entry" else {
            return nil
        }
        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }
        guard let slug = Slug(formatting: components.path) else {
            return nil
        }
        let title = components.firstQueryItemWhere(name: "title")?.value
        return slug.toUnqualifiedLink(title: title)
    }
}

extension Subtext {
    static func toSubURL(
        slug: String,
        title: String
    ) -> URL? {
        UnqualifiedLink(sluglike: slug, title: title)?
            .encodeAsSubEntryURL()
    }

    static func renderAttributesOf(
        _ attributedString: NSMutableAttributedString
    ) {
        renderAttributesOf(
            attributedString,
            url: toSubURL
        )
    }
}
