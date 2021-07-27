//
//  Slug.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/7/21.
//

import Foundation

/// A suite of tools for generating slugs.
extension String {
    /// Truncate to avoid file name length limit issues.
    /// Windows systems can handle up to 255, but we truncate at 200 to leave a bit of room
    /// for things like version numbers.
    func truncatingSafeFileNameLength() -> String {
        String(self.prefix(200))
    }

    /// Make filename compatible with Mac and FAT file systems by removing forbidden characters.
    func sanitizingFilename() -> String {
        // Replace slashes and pluses with dashes
        self
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
    func toFilename() -> String {
        self.sanitizingFilename().truncatingSafeFileNameLength()
    }

    /// Replace all runs of one or more whitespace characters
    /// with a single dash
    func replacingSpacesWithDash() -> String {
        self.replacingOccurrences(
            of: #"\s+"#,
            with: "-",
            options: .regularExpression,
            range: nil
        )
    }

    /// Remove any character that is not POSIX fully-portable filename.
    /// Basically anything not `[A–Za–z0–9._-]`.
    func removingNonPosixCharacters() -> String {
        self.replacingOccurrences(
            of: #"[^a-zA-Z0-9\._\-\s]"#,
            with: "",
            options: .regularExpression,
            range: nil
        )
    }

    /// Given a string, returns a slug suitable for using as a file name.
    /// Slug conforms to POSIX Fully Portable Filename format.
    func toSlug() -> String {
        self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingSpacesWithDash()
            .removingNonPosixCharacters()
            .truncatingSafeFileNameLength()
    }
}
