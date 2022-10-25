//
//  PathUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/21/22.
//
//  Utilities for "Paths" which are just strings.
//  There are a number of places where both Foundation and Subconscious
//  want to use Strings instead of URLs, particularly for relative paths.
//  We have a handful of utilities for working with path-like strings here.
//
//  Paths aren't really paths, so it's worthwhile to convert path-like strings
//  to URL before passing them to FileManager.

import Foundation

/// Pathlike is an alias for String, to make it clear we're using a string
/// as a path.
typealias Pathlike = String

extension Pathlike {
    /// Return path exension
    var ext: String {
        let parts = self.split(separator: ".")
        if parts.count > 1 {
            return String(parts[1])
        }
        return ""
    }
}

extension Pathlike {
    /// Returns a string path with the path extension removed, if any.
    /// Extension is anything after the first `.`.
    func deletingPathExtension() -> String {
        if let stem = self.split(separator: ".").first {
            return String(stem)
        }
        return self
    }
}

extension Pathlike {
    /// Append a file extension to a path-like string.
    ///
    /// The logic of this function is very simple, essentially a
    /// concatenation, so avoid doing anything pathological.
    ///
    /// Foundation is inconsistent in its treatment of paths.
    /// Some older APIs use strings. Newer APIs tend to use URLs.
    ///
    /// Having this utility is useful for e.g. converting slug to path.
    func appendingPathExtension(_ ext: String) -> String {
        "\(self).\(ext)"
    }
}

extension Pathlike {
    /// Check if a path-like string has an extension suffix.
    /// Pass the extension without the leading `.`.
    func hasExtension(_ ext: String) -> Bool {
        self.hasSuffix(".\(ext)")
    }
}

extension Pathlike {
    /// Truncate to avoid file name length limit issues.
    /// Windows systems can handle up to 255, but we truncate at 200 to leave a bit of room
    /// for things like version numbers.
    func truncatingSafeFileNameLength() -> String {
        String(self.prefix(200))
    }
}

extension Pathlike {
    func removingLeadingSlash() -> String {
        if self.hasPrefix("/") {
            return String(self.dropFirst())
        }
        return self
    }
}
