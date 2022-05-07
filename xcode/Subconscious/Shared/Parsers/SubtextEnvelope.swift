//
//  SubtextEnvelope.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation

struct SubtextEnvelope {
    var headers: Headers
    var body: Subtext

    /// Get title from headers, or derive title from Subtext body
    func title() -> String {
        if let header = headers.first(named: "title") {
            return header.value
        }
        return body.title()
    }

    func render() -> String {
        """
        \(headers.render())
        \(body.base)
        """
    }

    static func parse(_ tape: inout Tape) -> Self {
        let headers = Headers.parse(&tape)
        let dom = Subtext.parse(&tape)
        return Self(
            headers: headers,
            body: dom
        )
    }

    static func parse(markup: String) -> Self {
        var tape = Tape(markup[...])
        return parse(&tape)
    }
}
