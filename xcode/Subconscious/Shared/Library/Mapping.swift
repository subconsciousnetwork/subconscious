//
//  Coders.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// Mapping functions for translating between types

/// Mapping utilities
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
    static func from(_ string: String) -> Data? {
        string.data(using: .utf8)
    }
}

extension Data {
    static func from(_ subtext: Subtext) -> Data? {
        subtext.base |> String.from |> Data.from
    }
}

extension Subtext {
    static func from(_ data: Data) -> Subtext? {
        data |> String.from |> Subtext.parse(markup:)
    }
}

extension MemoData {
    static func from(_ data: Data) -> MemoData? {
        try? JSONDecoder.decode(data: data, type: MemoData.self)
    }
}

extension Data {
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
