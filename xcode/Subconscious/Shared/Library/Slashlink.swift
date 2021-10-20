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
    static func slugify(_ text: String) -> String {
        text
            .lowercased()
            // Replace runs of one or more space with a single dash
            .replacingOccurrences(
                of: #"\s+"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
            // Remove all non-slug characters
            .replacingOccurrences(
                of: #"[^a-zA-Z0-9_\-\/]"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
            .truncatingSafeFileNameLength()
            .ltrim(prefix: "/")
    }

    /// Given a slug, returns a string that is close-enough to prose text
    static func unslugify(_ slug: String) -> String {
        slug
            // Replace dash with space
            .replacingOccurrences(
                of: "-",
                with: " "
            )
            .firstUppercased()
    }

    static func slashlinkToURLString(_ text: String) -> String? {
        let slashlink = slugify(text)
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
        let slug = slugify(name)
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
