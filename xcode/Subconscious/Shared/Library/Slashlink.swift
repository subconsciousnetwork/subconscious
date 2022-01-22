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

    static func removeLeadingSlash(_ slug: String) -> String {
        if slug.hasPrefix("/") {
            return String(slug.dropFirst())
        }
        return slug
    }

    static func addLeadingSlash(_ slug: String) -> String {
        if !slug.hasPrefix("/") {
            return "/" + slug
        }
        return slug
    }

    /// Given a slug, returns a string that is close-enough to prose text
    static func unslugify(_ slug: Slug) -> String {
        removeLeadingSlash(slug)
            // Replace dash with space
            .replacingOccurrences(
                of: "-",
                with: " "
            )
            .firstUppercased()
    }

    static func slashlinkToURLString(_ text: String) -> String? {
        let slashlink = text.slugifyString()
        if let url = URL(string: "sub://slashlink/\(slashlink)") {
            return url.absoluteString
        }
        return nil
    }

    static func urlToSlug(_ url: URL) -> String {
        return removeLeadingSlash(url.path)
    }

    /// Given a URL, extract a string that is close-enough to prose.
    static func urlToProse(_ url: URL) -> String {
        return unslugify(url.path)
    }

    /// Find unique slashlink slug
    /// Slugifies name given.
    /// Appends a short random string to make the URL unique, if the URL already exists.
    static func findUniqueURL(
        at base: URL,
        name: String,
        ext: String
    ) -> URL {
        let slug = name.slugifyString()
        let url = base.appendingFilename(name: slug, ext: ext)
        if !FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        while true {
            let rand = String.randomAlphanumeric(length: 8)
            let slug = "\(slug)-\(rand)"
            let url = base.appendingFilename(name: slug, ext: ext)
            if !FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
    }
}
