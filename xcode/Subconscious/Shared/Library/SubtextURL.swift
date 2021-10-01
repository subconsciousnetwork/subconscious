//
//  SubtextURL.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import Foundation

enum SubtextURL {}

extension SubtextURL {
    static func isWikilinkURL(_ url: URL) -> Bool {
        url.scheme == "sub" && url.host == "wikilink"
    }

    static func wikilinkToURL(_ text: String) -> URL? {
        if let path = text.addingPercentEncoding(
            withAllowedCharacters: .urlHostAllowed
        ) {
            return URL(string: "sub://wikilink/\(path)")
        }
        return nil
    }

    static func wikilinkToURLString(_ text: String.SubSequence) -> String? {
        if
            let path = text.addingPercentEncoding(
                withAllowedCharacters: .urlHostAllowed
            ),
            let url = URL(string: "sub://wikilink/\(path)")
        {
            return url.absoluteString
        }
        return nil
    }

    static func urlToWikilink(_ url: URL) -> String? {
        if isWikilinkURL(url) {
            if let path = url.path.removingPercentEncoding {
                if path.hasPrefix("/") {
                    return String(path.dropFirst())
                }
                return path
            }
        }
        return nil
    }
}
