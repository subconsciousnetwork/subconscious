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
}
