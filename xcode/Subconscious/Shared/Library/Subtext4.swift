//
//  Subtext4.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/29/21.
//

import Foundation
import SwiftUI

struct Subtext4: Equatable {
    static let heading = try! NSRegularExpression(
        pattern: #"^#.*$"#,
        options: .anchorsMatchLines
    )

    static let slashlink = try! NSRegularExpression(
        pattern: #"(^|\s)(/[^\s]+)"#,
        options: .anchorsMatchLines
    )

    static let barelink = try! NSRegularExpression(
        pattern: #"https?://[^\s]+"#
    )

    static let bracketlink = try! NSRegularExpression(
        pattern: #"<([^>\s]+)>"#
    )

    /// Static property for empty document
    static let empty = Self(markup: "")

    let base: String
    let headings: [NSRange]
    let slashlinks: [NSRange]
    let barelinks: [NSRange]
    let bracketlinks: [NSRange]

    init(
        markup: String,
        cursor: String.Index? = nil
    ) {
        let nsRange = NSRange(markup.startIndex..<markup.endIndex, in: markup)
        self.base = markup
        self.headings = Self.heading.matches(
            in: markup,
            range: nsRange
        ).map({ result in
            result.range
        })
        self.slashlinks = Self.slashlink.matches(
            in: markup,
            range: nsRange
        ).map({ result in
            result.range(at: 2)
        })
        self.barelinks = Self.barelink.matches(
            in: markup,
            range: nsRange
        ).map({ result in
            result.range
        })
        self.bracketlinks = Self.bracketlink.matches(
            in: markup,
            range: nsRange
        ).map({ result in
            result.range(at: 1)
        })
    }

    init(
        markup: String,
        range: NSRange
    ) {
        let cursor = Range(range, in: markup)
        self.init(
            markup: markup,
            cursor: cursor?.lowerBound
        )
    }

    /// Render markup verbatim with syntax highlighting and links
    func renderMarkup(url: (Substring) -> String?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: base)
        // Set default styles for entire string
        attributedString.addAttribute(
            .font,
            value: UIFont.appText,
            range: NSRange(base.startIndex..<base.endIndex, in: base)
        )
        for nsRange in headings {
            attributedString.addAttribute(
                .font,
                value: UIFont.appTextBold,
                range: nsRange
            )
        }
        for nsRange in slashlinks {
            if
                let text = Range(nsRange, in: base).map({ range in
                    base[range]
                }),
                let url = url(text)
            {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: nsRange
                )
            }
        }
        for nsRange in barelinks {
            if let url = Range(nsRange, in: base).map({ range in
                base[range]
            }) {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: nsRange
                )
            }
        }
        for nsRange in bracketlinks {
            if let url = Range(nsRange, in: base).map({ range in
                base[range]
            }) {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: nsRange
                )
            }
        }
        return attributedString
    }
}
