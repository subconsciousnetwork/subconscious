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
    static let schemeKey = "sub"
    static let hostKey = "link"
    static let slashlinkKey = "slashlink"
    static let textKey = "text"

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
        components.scheme = Self.schemeKey
        components.host = Self.hostKey
        var query: [URLQueryItem] = []
        query.append(
            URLQueryItem(
                name: Self.slashlinkKey,
                value: slashlink.description
            )
        )
        if let text = text {
            query.append(
                URLQueryItem(
                    name: Self.textKey,
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
        guard
            self.scheme == SubSlashlinkLink.schemeKey &&
            self.host == SubSlashlinkLink.hostKey
        else {
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

extension Range where Bound == String.Index {
    func within(
        attributedString: AttributedString
    ) -> Range<AttributedString.Index>? {
        guard let lower = AttributedString.Index(
            self.lowerBound,
            within: attributedString
        ) else {
            return nil
        }
        guard let upper = AttributedString.Index(
            self.upperBound,
            within: attributedString
        ) else {
            return nil
        }
        return lower..<upper
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

    /// Render string to new-style SwiftUI AttributedString
    /// You can use this to produce strings which can be rendered in
    /// `Text` blocks.
    func render(_ string: String) -> AttributedString {
        let dom = Subtext(markup: string)

        var markup = AttributedString(dom.base)
        markup.font = .body
        
        for block in dom.blocks {
            renderAttributesOf(attributedString: &markup, block: block)
            for inline in block.inline {
                renderAttributesOf(
                    attributedString: &markup,
                    inline: inline
                )
            }
        }
        
        return markup
    }

    func renderAttributesOf(
        attributedString: inout AttributedString,
        block: Subtext.Block
    ) {
        switch block {
        case .quote(let span, _):
            guard let range = span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            attributedString[range].font = .body.italic()
        case .heading(let span):
            guard let range = span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            attributedString[range].font = .body.bold()
        default:
            return
        }
    }

    func renderAttributesOf(
        attributedString: inout AttributedString,
        inline: Subtext.Inline
    ) {
        switch inline {
        case .link(let link):
            guard let range = link.span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            attributedString[range].link = URL(
                string: String(link.body())
            )
        case .bracketlink(let bracketlink):
            guard let range = bracketlink.span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            attributedString[range].link = URL(
                string: String(bracketlink.body())
            )
        case .slashlink(let slashlink):
            guard let range = slashlink.span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            guard let url = slashlinkToURL(slashlink.description) else {
                return
            }
            attributedString[range].link = url
        case .wikilink(let wikilink):
            guard let wikilinkRange = wikilink.span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            guard let textRange = wikilink.text.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            guard let url = wikilinkToURL(wikilink.description) else {
                return
            }
            attributedString[wikilinkRange].foregroundColor = .tertiaryLabel
            attributedString[textRange].foregroundColor = .accentColor
            attributedString[textRange].link = url
        case .bold(let bold):
            guard let range = bold.span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            attributedString[range].font = .body.bold()
        case .italic(let italic):
            guard let range = italic.span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            attributedString[range].font = .body.italic()
        case .code(let code):
            guard let range = code.span.range.within(
                attributedString: attributedString
            ) else {
                return
            }
            attributedString[range].backgroundColor = Color.secondaryBackground
            attributedString[range].font = .body.monospaced()
        }
    }

    /// Read markup in NSMutableAttributedString, and render as attributes.
    /// Resets all attributes on string, replacing them with style attributes
    /// corresponding to the semantic meaning of Subtext markup.
    @discardableResult func renderAttributesOf(
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
