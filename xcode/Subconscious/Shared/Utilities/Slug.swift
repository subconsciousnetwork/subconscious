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
    /// Windows systems can handle up to 255, but 140 is a nice Tweet-sized number.
    static func truncatingSafeFileNameLength(_ text: String) -> String {
        String(text.prefix(140))
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

    /// Remove any character that is "strange".
    /// Basically anything not `[A–Za–z0–9._-]` or a space character.
    static func removingStrangeCharacters(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"[^a-zA-Z0-9\._\-\s]"#,
            with: "",
            options: .regularExpression,
            range: nil
        )
    }

    /// Given a string, returns a new string that is safe to use as a filename in modern file systems.
    /// - Whitespace is trimmed from ends.
    /// - Strange characters that are invalid in some file systems are removed.
    /// - Text is truncated to stay under file name length limits in some file systems.
    /// Note it is possible for this method to return an empty string, so you should handle that case.
    static func toFilename(_ text: String) -> String {
        let portable = removingStrangeCharacters(text)
        let truncated = truncatingSafeFileNameLength(portable)
        let trimmed = truncated.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed
    }
    
    /// Given a string, returns a slug suitable for using as a file name.
    /// Slug conforms to POSIX Fully Portable Filename format.
    static func toSlug(_ text: String) -> String {
        let filename = toFilename(text)
        let lower = filename.lowercased()
        let dashed = replacingSpacesWithDash(lower)
        return dashed
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
    
    static func appendingExtension(
        path: String,
        extension ext: String
    ) -> String {
        [path, ext].joined(separator: ".")
    }
}
