//
//  FileManagerExtensions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//

import Foundation

extension FileManager {
    /// Recursively search for files under a directory
    /// Returns an array of file-URL paths that are not directories,
    /// if successful.
    /// Returns nil if there is an error.
    func listFilesDeep(
        at directory: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions = []
    ) -> [URL]? {
        if let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: mask
        ) {
            var urls: [URL] = []
            for case let url as URL in enumerator {
                if !url.hasDirectoryPath {
                    urls.append(url)
                }
            }
            return urls
        }
        return nil
    }
}
