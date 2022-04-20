//
//  Slashlink.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import Foundation

enum Slashlink {}

extension Slashlink {
    static func isSlashlinkURL(_ url: URL) -> Bool {
        url.scheme == "sub" && url.host == "slashlink"
    }

    static func slashlinkURLToSlug(_ url: URL) -> Slug? {
        guard isSlashlinkURL(url) else {
            return nil
        }
        return Slug(formatting: url.path)
    }
}

extension EntryLink {
    /// Create a Subconscious app-specific URL encoding entry title and slug
    func encodeAsSubEntryURL() -> URL? {
        guard var components = URLComponents(
            string: "sub://entry"
        ) else {
            return nil
        }
        components.path = self.slug.toSlashlink()
        components.queryItems = [
            URLQueryItem(name: "title", value: self.title),
        ]
        return components.url
    }

    /// Construct entry link from sub entry URL
    static func decodefromSubEntryURL(_ url: URL) -> EntryLink? {
        guard url.scheme == "sub" && url.host == "entry" else {
            return nil
        }
        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }
        let slug = Slug(formatting: components.path)
        let query = components.indexQueryItems()
        let title = query["title"] ?? nil
        if let title = title, let slug = slug {
            return EntryLink(slug: slug, title: title)
        } else if let slug = slug {
            return EntryLink(slug: slug)
        }
        return nil
    }
}

extension Subtext {
    private static func slashlinkToURLString(_ text: String) -> String? {
        if
            let slashlink = Slug(formatting: text),
            let url = URL(string: "sub://slashlink/\(slashlink.description)")
        {
            return url.absoluteString
        }
        return nil
    }

    static func renderAttributesOf(
        _ attributedString: NSMutableAttributedString
    ) {
        renderAttributesOf(
            attributedString,
            url: slashlinkToURLString
        )
    }
}
