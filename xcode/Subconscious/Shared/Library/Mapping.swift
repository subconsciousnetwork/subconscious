//
//  Coders.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//
// Mapping functions for translating between types.

import Foundation

extension String {
    /// Get string from substring
    static func from(_ substring: Substring) -> String {
        String(substring)
    }
}

extension String {
    /// Get string from Data, using UTF-8 encoding.
    static func from(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
}

extension Data {
    /// Encode string to data, using UTF-8 encoding.
    static func from(_ string: String) -> Data? {
        string.data(using: .utf8)
    }
}

extension Data {
    /// Encode Subtext to Data
    static func from(_ subtext: Subtext) -> Data? {
        subtext.base |> String.from |> Data.from
    }
}

extension Subtext {
    /// Decode Subtext from Data
    static func from(_ data: Data) -> Subtext? {
        data |> String.from |> Subtext.parse(markup:)
    }
}

extension MemoData {
    /// Decode MemoData from Data
    static func from(_ data: Data) -> MemoData? {
        let decoder = JSONDecoder()
        return try? decoder.decode(MemoData.self, from: data)
    }
}

extension Data {
    /// Encode MemoData to Data
    static func from(_ memo: MemoData) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(memo)
    }
}

extension Memo {
    /// Read a Subtext-flavored Memo from a string
    /// - Parses headers (if any)
    /// - Parses body as Subtext
    static func from(_ string: String) -> Memo? {
        let envelope = HeadersEnvelope(markup: string)
        let headers = envelope.headers
        let wellKnownHeaders = WellKnownHeaders(
            headers: headers,
            fallback: WellKnownHeaders(
                contentType: ContentType.text.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "",
                fileExtension: ContentType.text.fileExtension
            )
        )
        return Memo(
            contentType: wellKnownHeaders.contentType,
            created: wellKnownHeaders.created,
            modified: wellKnownHeaders.modified,
            title: wellKnownHeaders.title,
            fileExtension: wellKnownHeaders.fileExtension,
            other: headers,
            body: String(envelope.body)
        )
    }
    
}

extension Memo {
    /// Read SubtextMemo from data
    static func from(_ data: Data) -> Memo? {
        String.from(data) |> Memo.from
    }
}

extension String {
    /// Encode Date to ISO8601 String
    static func from(_ date: Date) -> String {
        date.ISO8601Format()
    }
}

extension Date {
    /// Decode Date from ISO8601 String
    static func from(_ iso8601String: String) -> Date? {
        guard let date = try? Date(iso8601String, strategy: .iso8601) else {
            return nil
        }
        return date
    }
}

extension Story {
    static func from(_ data: Data) -> Story? {
        let decoder = JSONDecoder()
        return try? decoder.decode(Story.self, from: data)
    }
}

extension Data {
    static func from(_ story: Story) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(story)
    }
}
