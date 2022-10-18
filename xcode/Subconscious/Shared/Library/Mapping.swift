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
        try? JSONDecoder.decode(data: data, type: MemoData.self)
    }
}

extension Data {
    /// Encode MemoData to Data
    static func from(_ memo: MemoData) -> Data? {
        try? JSONEncoder.encode(memo)
    }
}

extension SubtextMemo {
    /// Read a Subtext-flavored Memo from a string
    /// - Parses headers (if any)
    /// - Parses contents as Subtext
    static func from(_ string: String) -> SubtextMemo? {
        let envelope = HeadersEnvelope(markup: string)
        let subtext = Subtext(markup: String(envelope.body))
        return Memo<Subtext>(headers: envelope.headers, contents: subtext)
    }
    
}

extension SubtextMemo {
    /// Read SubtextMemo from data
    static func from(_ data: Data) -> SubtextMemo? {
        String.from(data) |> SubtextMemo.from
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
