//
//  URLUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/26/21.
//

import Foundation

extension URL {
    /// Add file name component to URL with extension
    /// - Returns: new URL
    func appendingFilename(name: String, ext: String) -> URL {
        var url = self
        url.appendPathComponent(name)
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
