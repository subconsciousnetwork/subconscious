//
//  DateFormatterUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import Foundation

extension RelativeDateTimeFormatter {
    static func short(
        locale: Locale = Locale.current
    ) -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .short
        return formatter
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
