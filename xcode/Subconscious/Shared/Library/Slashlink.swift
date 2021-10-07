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

    /// Given a string, returns a slashlink slug *without* the slash prefix.
    static func toSlug(_ text: String) -> String {
        text
            .lowercased()
            .replacingSpacesWithDash()
            .removingNonPosixCharacters()
            .truncatingSafeFileNameLength()
            .ltrim(prefix: "/")
    }

    static func slashlinkToURLString(_ text: String) -> String? {
        let slashlink = toSlug(text)
        if let url = URL(string: "sub://slashlink/\(slashlink)") {
            return url.absoluteString
        }
        return nil
    }

    static func urlToSlashlinkString(_ url: URL) -> String? {
        if isSlashlinkURL(url) {
            if url.path.hasPrefix("/") {
                return String(url.path.dropFirst())
            }
        }
        return nil
    }

    /// Find unique slashlink slug
    /// Slugifies name given.
    /// Appends a short random string to make the URL unique, if the URL already exists.
    static func findUniqueURL(
        at base: URL,
        name: String,
        ext: String
    ) -> URL {
        let slug = toSlug(name)
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
