//
//  DateFormatterUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import Foundation

/// A struct containing logic for nice dates
/// Display times for same-day dates, or short dates, otherwise
struct NiceDateFormatter {
    static let shared = NiceDateFormatter()
    private var dateFormatter: DateFormatter
    private var timeFormatter: DateFormatter

    init(locale: Locale = Locale.current) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        self.dateFormatter = dateFormatter

        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.dateFormat = "HH:mm"
        self.timeFormatter = timeFormatter
    }

    func string(from date: Date, relativeTo now: Date = Date.now) -> String {
        if Calendar.current.isDate(date, inSameDayAs: now) {
            return timeFormatter.string(from: date)
        } else {
            return dateFormatter.string(from: date)
        }
    }
}

extension DateFormatter {
    static func yyyymmdd(locale: Locale = Locale.current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

extension DateFormatter {
    static func scratchDateFormatter(
        locale: Locale = Locale.current
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }
}

extension ISO8601DateFormatter {
    static func internet(
        timeZone: TimeZone = TimeZone.current
    ) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone
        formatter.formatOptions = [
            .withFullDate,
            .withTime,
            .withDashSeparatorInDate
        ]
        return formatter
    }
}
