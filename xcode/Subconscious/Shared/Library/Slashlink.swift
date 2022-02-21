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

    static func slashlinkToURLString(_ text: String) -> String? {
        if
            let slashlink = Slug(formatting: text),
            let url = URL(string: "sub://slashlink/\(slashlink.description)")
        {
            return url.absoluteString
        }
        return nil
    }

    static func slashlinkURLToSlug(_ url: URL) -> Slug? {
        guard isSlashlinkURL(url) else {
            return nil
        }
        return Slug(formatting: url.path)
    }
}

// Implement renderable for Subtext
extension Subtext: MarkupConvertable {
    func render() -> NSAttributedString {
        self.render(url: Subconscious.Slashlink.slashlinkToURLString)
    }
}
