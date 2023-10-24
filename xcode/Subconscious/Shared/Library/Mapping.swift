//
//  Coders.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//
// Mapping functions for translating between types.

import Foundation

extension Substring {
    func toString() -> String {
        String(self)
    }
}

extension Data {
    func toString(encoding: String.Encoding = .utf8) -> String? {
        String(data: self, encoding: encoding)
    }
}

extension String {
    func toData(encoding: String.Encoding = .utf8) -> Data? {
        self.data(using: .utf8)
    }
}

extension String {
    func toSubtext() -> Subtext {
        Subtext.parse(markup: self)
    }
}

extension Subtext {
    func toData() -> Data? {
        self.base.toString().toData()
    }
}

extension Data {
    func toSubtext() -> Subtext? {
        self.toString()?.toSubtext()
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
    
    /// Decode date from optional iso8601String
    static func from(_ iso8601String: String?) -> Date? {
        guard let iso8601String = iso8601String else {
            return nil
        }
        return Date.from(iso8601String)
    }
}
