//
//  SubtextEnvelope.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation

struct SubtextEnvelope: Hashable, CustomStringConvertible {
    var headers: HeaderIndex
    var body: Subtext

    init(
        headers: HeaderIndex,
        body: Subtext
    ) {
        self.headers = headers
        self.body = body
    }

    var description: String {
        "\(headers)\(body.base)"
    }

    /// Append one SubtextEnvelope to another.
    /// Adds headers from `other` if they are not currently present,
    /// but does not overwrite headers.
    func append(_ other: SubtextEnvelope) -> Self {
        var this = self
        this.headers = this.headers.merge(other.headers)
        this.body = this.body.append(other.body)
        return this
    }

    static func parse(markup: String) -> Self {
        let envelope = HeadersEnvelope.parse(markup: markup)
        let headers = HeaderIndex(envelope.headers)
        let dom = Subtext.parse(markup: String(envelope.body))
        return Self(
            headers: headers,
            body: dom
        )
    }
}
