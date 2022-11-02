//
//  Memo.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// A "reified" memo who's bodypart has been loaded and decoded to a string.
/// We have a few required header fields that we also represent as fields of
/// the struct.
struct Memo: Hashable, CustomStringConvertible {
    var contentType: String
    var created: Date
    var modified: Date
    var title: String
    var fileExtension: String
    var other: Headers
    var body: String
    
    /// Get combined headers.
    /// Properties that represent well-known headers will override
    /// headers in `other`.
    var headers: Headers {
        Headers(
            contentType: self.contentType,
            created: self.created,
            modified: self.modified,
            title: self.title,
            fileExtension: fileExtension
        )
        .merge(other)
    }
    
    var description: String { body }
    
    /// Generates a plain text description
    func plain() -> String {
        switch ContentType(rawValue: contentType) {
        case .subtext:
            return body
        case .text:
            return body
        default:
            return ""
        }
    }
    
    /// Derive an excerpt from this memo.
    /// Uses content type to try to make a best guess.
    func excerpt() -> String {
        switch ContentType(rawValue: contentType) {
        case .subtext:
            return Subtext(markup: body).excerpt()
        case .text:
            return body.truncatingByWord(characters: 240)
        default:
            return ""
        }
    }
    
    /// Read slugs referenced in memo body
    func slugs() -> Set<Slug> {
        switch ContentType(rawValue: contentType) {
        case .subtext:
            let subtext = Subtext(markup: body)
            return subtext.slugs
        default:
            return Set()
        }
    }
    
    /// Create `WellKnownHeaders` from memo
    func wellKnownHeaders() -> WellKnownHeaders {
        WellKnownHeaders(
            contentType: contentType,
            created: created,
            modified: modified,
            title: title,
            fileExtension: fileExtension
        )
    }
}
