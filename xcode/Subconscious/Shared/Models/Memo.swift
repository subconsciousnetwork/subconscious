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
    var additionalHeaders: Headers
    var body: String
    
    /// Get combined headers.
    /// Properties that represent well-known headers will override
    /// headers in `other`.
    var headers: Headers {
        WellKnownHeaders(
            contentType: contentType,
            created: created,
            modified: modified,
            title: title,
            fileExtension: fileExtension
        )
        .getAdditionalHeaders()
        .merge(additionalHeaders)
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
    
    /// Merge another memo into this one.
    /// Headers from this instance win, however additional headers are merged.
    func merge(_ that: Memo) -> Self {
        var this = self
        this.additionalHeaders = this.additionalHeaders.merge(
            that.additionalHeaders
        )
        let concatenated = "\(this.body)\n\n\(that.body)"
        this.body = concatenated
        return this
    }
}

extension MemoData {
    /// Create a memo from MemoData, with defaults for missing headers
    func toMemo(
        created: Date = Date.now,
        modified: Date = Date.now,
        title: String = "",
        fileExtension: String = "subtext"
    ) -> Memo? {
        guard let body = self.body.toString() else {
            return nil
        }

        let headers = WellKnownHeaders(
            contentType: self.contentType,
            created: created,
            modified: modified,
            title: title,
            fileExtension: fileExtension
        )
        .updating(self.additionalHeaders)

        return Memo(
            contentType: headers.contentType,
            created: headers.created,
            modified: headers.modified,
            title: headers.title,
            fileExtension: headers.fileExtension,
            additionalHeaders: [],
            body: body
        )
    }
}
