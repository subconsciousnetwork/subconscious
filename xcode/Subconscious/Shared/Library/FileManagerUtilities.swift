//
//  FileManagerExtensions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//

import Foundation

extension FileManager {
    /// Get the URL for the user's document directory, if any.
    var documentDirectoryUrl: URL? {
        self.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    /// Simplified form of `contentsOfDirectory`.
    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try self.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
    }

    func fileExists(atURL url: URL) -> Bool {
        self.fileExists(atPath: url.path)
    }

    /// Get a unique versioned filename for file, given a base URL, name, extension.
    /// Increments version until it finds a unique filename.
    /// - Returns: URL
    func findUniqueFilename(
        at url: URL,
        name: String,
        ext: String,
        version: Int = 1
    ) -> URL? {
        guard url.isFileURL && url.hasDirectoryPath else {
            return nil
        }

        // Only version numbers one and above, please.
        let version = max(version, 1)

        let versionedURL = url.appendingVersionedFilename(
            name: name,
            ext: ext,
            version: version
        )

        if self.fileExists(atURL: versionedURL) {
            return findUniqueFilename(
                at: url,
                name: name,
                ext: ext,
                version: version + 1
            )
        } else {
            return versionedURL
        }
    }
}
