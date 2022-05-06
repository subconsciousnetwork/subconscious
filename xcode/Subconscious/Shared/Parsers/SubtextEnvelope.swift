//
//  SubtextEnvelope.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation

struct SubtextEnvelope {
    let headers: Headers
    let body: Subtext

    private init(
        headers: Headers,
        body: Subtext
    ) {
        self.headers = headers
        self.body = body
    }

    static func parse(markup: String) -> Self {
        var tape = Tape(markup[...])
        let headers = Headers.parse(&tape)
        let dom = Subtext.parse(&tape)
        return Self(
            headers: headers,
            body: dom
        )
    }
}
