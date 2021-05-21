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

    /// List all URLs for files in the user's document directory.
    /// Omits hidden files.
    func listDocumentDirectoryContents() -> [URL] {
        if let dir = self.documentDirectoryUrl {
            let files = try? self.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            return files ?? []
        } else {
            return []
        }
    }
}
