//
//  HeaderSubtext.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 11/4/22.
//

import Foundation

struct HeaderSubtext: Hashable, CustomStringConvertible {
    var headers = Headers()
    var body: String
    
    var description: String {
        "\(headers.toHeaderString())\(body)"
    }
    
    func toMarkup() -> String {
        self.description
    }

    /// Calculate size of text, including inlined headers
    func size() -> Int? {
        description.toData(encoding: .utf8)?.count
    }
}

extension String {
    func toHeaderSubtext() -> HeaderSubtext {
        let envelope = HeadersEnvelope(markup: self)
        return HeaderSubtext(headers: envelope.headers, body: envelope.body)
    }
}

extension Memo {
    func toHeaderSubtext() -> HeaderSubtext {
        HeaderSubtext(
            headers: self.headers,
            body: self.body
        )
    }
}

extension HeaderSubtext {
    func toMemo(
        fallback: WellKnownHeaders = WellKnownHeaders(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension
        )
    ) -> Memo? {
        let wellKnownHeaders = fallback.updating(headers)
        return Memo(
            contentType: wellKnownHeaders.contentType,
            created: wellKnownHeaders.created,
            modified: wellKnownHeaders.modified,
            fileExtension: wellKnownHeaders.fileExtension,
            color: wellKnownHeaders.color,
            additionalHeaders: headers,
            body: body
        )
    }
}
