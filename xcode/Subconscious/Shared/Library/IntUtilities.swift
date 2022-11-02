//
//  IntUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/22.
//

import Foundation

extension Int {
    /// Create an integer from an ISO8601 date string.
    /// - Returns int that represents seconds since Unix epoch until date.
    static func from(iso8601String: String) -> Int? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate,
            .withTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime
        ]
        guard let date = formatter.date(from: iso8601String) else {
            return nil
        }
        return Int(date.timeIntervalSince1970)
    }
}
