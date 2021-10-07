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

    static func toNormalizedSlashlink(_ text: String) -> String {
        let slug = text
            .lowercased()
            .replacingSpacesWithDash()
            .removingNonPosixCharacters()
            .truncatingSafeFileNameLength()
        if slug.hasPrefix("/") {
            return text
        } else {
            return "/\(text)"
        }
    }

    static func slashlinkToURLString(_ text: String) -> String? {
        let slashlink = toNormalizedSlashlink(text)
        if let url = URL(string: "sub://slashlink\(slashlink)") {
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
}
