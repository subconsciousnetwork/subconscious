//
//  Slug.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/7/21.
//

import Foundation

/// A suite of tools for generating slugs.
struct Slug {
    /// Truncate to avoid file name length limit issues.
    /// Windows systems can handle up to 255, but we truncate at 200 to leave a bit of room
    /// for things like version numbers.
    static func truncatingSafeFileNameLength(_ text: String) -> String {
        String(text.prefix(200))
    }

    /// Make filename compatible with Mac and FAT file systems by removing forbidden characters.
    static func sanitizingFilename(_ text: String) -> String {
        // Replace slashes and pluses with dashes
        text
            .replacingOccurrences(
                of: #"[\:\/\\\+]"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
            // Remove other stuff
            .replacingOccurrences(
                of: #"[\*\<\>\?\|\,\.\;\=\[\]]"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
    }

    /// Sanitize and truncate text so that it is suitible as a Mac/FAT filename.
    static func toFilename(_ text: String) -> String {
        truncatingSafeFileNameLength(sanitizingFilename(text))
    }

    /// Replace all runs of one or more whitespace characters
    /// with a single dash
    static func replacingSpacesWithDash(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"\s+"#,
            with: "-",
            options: .regularExpression,
            range: nil
        )
    }

    /// Remove any character that is not POSIX fully-portable filename.
    /// Basically anything not `[A–Za–z0–9._-]`.
    static func removingNonPosixCharacters(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"[^a-zA-Z0-9\._\-\s]"#,
            with: "",
            options: .regularExpression,
            range: nil
        )
    }

    /// Given a string, returns a slug suitable for using as a file name.
    /// Slug conforms to POSIX Fully Portable Filename format.
    static func toSlug(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let dashed = replacingSpacesWithDash(lower)
        let portable = removingNonPosixCharacters(dashed)
        let truncated = truncatingSafeFileNameLength(portable)
        return truncated
    }

    /// Given a string, returns a slug prefixed with ISO8601 date.
    /// Slug conforms to POSIX Fully Portable Filename format.
    static func toSlugWithDate(_ text: String, date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate,
            .withDashSeparatorInDate
        ]
        let isodate = formatter.string(from: date)
        let slug = toSlug(text)
        if slug.count > 0 {
            return "\(isodate)-\(slug)"
        } else {
            return isodate
        }
    }
}
