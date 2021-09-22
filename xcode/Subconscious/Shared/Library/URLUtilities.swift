//
//  URLUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/26/21.
//

import Foundation

extension URL {
    /// The stem of a URL, e.g. the file name without extension.
    var stem: String {
        self.deletingPathExtension().lastPathComponent
    }

    /// Add file name component to URL with extension
    /// - Returns: new URL
    func appendingFilename(name: String, ext: String) -> URL? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return nil
        }
        var url = self
        url.appendPathComponent(name)
        url.appendPathExtension(ext)
        return url
    }

    /// Add file name component to URL with version and extension.
    /// Useful for uniqueing file names.
    /// - Returns: new URL
    func appendingVersionedFilename(
        name: String,
        ext: String,
        version: Int = 1,
        untitled: String = "Untitled"
    ) -> URL {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? untitled : name
        var url = self
        // Only version numbers one and above, please.
        let version = max(version, 1)
        // Only append version number if > 0.
        let versionedName = version == 1 ? name : "\(name) \(version)"
        url.appendPathComponent(versionedName, isDirectory: false)
        url.appendPathExtension(ext)
        return url
    }

    /// Return path relative to some base
    /// If URL does not start with base, returns nil.
    func relativizingPath(relativeTo base: URL) -> String? {
        // Standardize and absolutize paths to normalize them
        let path = self.standardizedFileURL.absoluteString
        let basePath = base.standardizedFileURL.absoluteString
        if path.hasPrefix(basePath) {
            // Return path without standardized percent encoding.
            return path.ltrim(prefix: basePath).removingPercentEncoding
        }
        return nil
    }
}

extension Sequence where Iterator.Element == URL {
    func withPathExtension(_ ext: String) -> [URL] {
        self.filter({url in url.pathExtension == ext})
    }
}
