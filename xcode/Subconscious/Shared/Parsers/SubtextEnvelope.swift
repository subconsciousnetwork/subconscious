//
//  SubtextEnvelope.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation

struct SubtextEnvelope: Hashable, CustomStringConvertible {
    var headers: Headers
    var body: Subtext

    /// Get title from headers, or derive title from Subtext body
    func title() -> String {
        if let header = headers.first(named: "title") {
            return header.value
        }
        return body.title()
    }

    var description: String {
        "\(headers)\(body.base)"
    }

    /// Append one SubtextEnvelope to another.
    /// Discards the headers of `other`.
    func append(_ other: SubtextEnvelope) -> Self {
        var this = self
        this.body = this.body.append(other.body)
        return this
    }

    static func parse(markup: String) -> Self {
        let envelope = HeadersEnvelope.parse(markup: markup)
        let dom = Subtext.parse(markup: String(envelope.body))
        return Self(
            headers: envelope.headers,
            body: dom
        )
    }
}
