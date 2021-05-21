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
    func appendingFilename(name: String, ext: String) -> URL {
        var url = self
        url.appendPathComponent(name)
        url.appendPathExtension(ext)
        return url
    }
}

extension Sequence where Iterator.Element == URL {
    func withPathExtension(_ ext: String) -> [URL] {
        self.filter({url in url.pathExtension == ext})
    }
}
