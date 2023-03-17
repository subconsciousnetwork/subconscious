//
//  SubtextAttributedStringRenderer.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/8/23.
//
import Foundation
import SwiftUI

/// A type that can be encoded and decoded to `sub://slashlink` URLs.
/// Used by `SubtextAttributedStringRenderer`.
struct SubSlashlinkLink {
    /// Link address
    var slashlink: Slashlink
    /// Link text
    var text: String?

    /// Get fallback content from SlashlinkURL
    /// Uses text if present, otherwise derives from slashlink.
    var fallback: String {
        text ?? slashlink.toSlug().toTitle()
    }

    /// Create a Subconscious app-specific URL encoding entry title and slug
    func toURL() -> URL? {
        var components = URLComponents()
        components.scheme = "sub"
        components.host = "slashlink"
        var query: [URLQueryItem] = []
        query.append(
            URLQueryItem(
                name: "slashlink",
                value: slashlink.description
            )
        )
        if let text = text {
            query.append(
                URLQueryItem(
                    name: "text",
                    value: text
                )
            )
        }
        components.queryItems = query
        return components.url
    }
}

extension URL {
    /// Convert to internal `sub://slashlink` URL.
    func toSubSlashlinkURL() -> SubSlashlinkLink? {
        guard self.scheme == "sub" && self.host == "slashlink" else {
            return nil
        }
        guard let components = URLComponents(
            url: self,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        guard let slashlinkQuery = components.firstQueryValueWhere(
            name: "slashlink"
        ) else {
            return nil
        }

        guard let slashlink = Slashlink(slashlinkQuery) else {
            return nil
        }

        let text = components.firstQueryValueWhere(name: "text")

        return SubSlashlinkLink(
            slashlink: slashlink,
            text: text
        )
    }
}

/// Render subtext attributes to attributed strings.
/// Instances of this struct can customize rendering logic by
/// overriding delegate methods.
struct SubtextAttributedStringRenderer {
    static func wikilinkToURL(_ text: String) -> URL? {
        guard let slug = Slug(formatting: text) else {
            return nil
        }
        let sub = SubSlashlinkLink(
            slashlink: slug.toSlashlink(),
            text: text
        )
        return sub.toURL()
    }

    static func slashlinkToURL(_ string: String) -> URL? {
        guard let slashlink = Slashlink(string) else {
            return nil
        }
        let sub = SubSlashlinkLink(slashlink: slashlink)
        return sub.toURL()
    }
    
    /// Body font size. Should be passed down from view using
    /// `@ScaledMetric(relativeTo: .body)`.
    var bodySize: CGFloat = AppTheme.textSize
    /// Delegate allowing slashlink-to-url override
    var slashlinkToURL: (String) -> URL? = Self.slashlinkToURL
    /// Delegate allowing wikilink-to-url override
    var wikilinkToURL: (String) -> URL? = Self.wikilinkToURL
    
    /// Read markup in NSMutableAttributedString, and render as attributes.
    /// Resets all attributes on string, replacing them with style attributes
    /// corresponding to the semantic meaning of Subtext markup.
    func renderAttributesOf(
        _ attributedString: NSMutableAttributedString
    ) -> Subtext {
        let dom = Subtext(markup: attributedString.string)
        
        renderStandardAttributesOf(attributedString)
        
        for block in dom.blocks {
            renderBlockAttributesOf(
                attributedString,
                block: block
            )
        }
        
        return dom
    }

    private func renderStandardAttributesOf(
        _ attributedString: NSMutableAttributedString
    ) {
        // Get range of all text, using new Swift NSRange constructor
        // that takes a Swift range which knows how to handle Unicode
        // glyphs correctly.
        let baseNSRange = NSRange(
            attributedString.string.startIndex...,
            in: attributedString.string
        )
        
        // Clear all attributes before rendering
        attributedString.setAttributes([:], range: baseNSRange)
        
        // Set default font for entire string
        attributedString.addAttribute(
            .font,
            value: UIFont.appTextMono.withSize(bodySize),
            range: baseNSRange
        )
        
        // Set line-spacing for entire string
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = AppTheme.lineSpacing
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: baseNSRange
        )
        
        // Set text color
        attributedString.addAttribute(
            .foregroundColor,
            value: UIColor(Color.primary),
            range: baseNSRange
        )
    }

    /// Read markup in NSMutableAttributedString, and render as attributes.
    /// Resets all attributes on string, replacing them with style attributes
    /// corresponding to the semantic meaning of Subtext markup.
    private func renderBlockAttributesOf(
        _ attributedString: NSMutableAttributedString,
        block: Subtext.Block
    ) {
        switch block {
        case .empty:
            break
        case let .heading(line):
            let nsRange = NSRange(line.range, in: attributedString.string)
            attributedString.addAttribute(
                .font,
                value: UIFont.appTextMonoBold,
                range: nsRange
            )
        case .list(_, let inline):
            for inline in inline {
                renderInlineAttributeOf(
                    attributedString,
                    inline: inline
                )
            }
        case .quote(let line, let inline):
            let nsRange = NSRange(line.range, in: attributedString.string)
            attributedString.addAttribute(
                .font,
                value: UIFont.appTextMonoItalic,
                range: nsRange
            )
            for inline in inline {
                renderInlineAttributeOf(
                    attributedString,
                    inline: inline
                )
            }
        case .text(_, let inline):
            for inline in inline {
                renderInlineAttributeOf(
                    attributedString,
                    inline: inline
                )
            }
        }
    }

    private func renderInlineAttributeOf(
        _ attributedString: NSMutableAttributedString,
        inline: Subtext.Inline
    ) {
        switch inline {
        case let .link(link):
            if let url = link.url {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: NSRange(
                        link.span.range,
                        in: attributedString.string
                    )
                )
            }
        case let .bracketlink(bracketlink):
            if let url = bracketlink.url {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor(Color.tertiaryLabel),
                    range: NSRange(
                        bracketlink.span.range,
                        in: attributedString.string
                    )
                )
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: NSRange(
                        bracketlink.body().range,
                        in: attributedString.string
                    )
                )
            }
        case let .slashlink(slashlink):
            if let url = slashlinkToURL(slashlink.description) {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: NSRange(
                        slashlink.span.range,
                        in: attributedString.string
                    )
                )
            }
        case let .wikilink(wikilink):
            let text = String(wikilink.text)
            if let url = wikilinkToURL(text) {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor(Color.tertiaryLabel),
                    range: NSRange(
                        wikilink.span.range,
                        in: attributedString.string
                    )
                )
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: NSRange(
                        wikilink.text.range,
                        in: attributedString.string
                    )
                )
            }
        case .bold(let bold):
            attributedString.addAttribute(
                .font,
                value: UIFont.appTextMonoBold,
                range: NSRange(
                    bold.span.range,
                    in: attributedString.string
                )
            )
        case .italic(let italic):
            attributedString.addAttribute(
                .font,
                value: UIFont.appTextMonoItalic,
                range: NSRange(
                    italic.span.range,
                    in: attributedString.string
                )
            )
        case .code(let code):
            attributedString.addAttribute(
                .backgroundColor,
                value: UIColor(Color.secondaryBackground),
                range: NSRange(
                    code.span.range,
                    in: attributedString.string
                )
            )
        }
    }
}
