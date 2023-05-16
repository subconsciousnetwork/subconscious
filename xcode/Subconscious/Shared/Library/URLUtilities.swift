//
//  URLUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/26/21.
//

import Foundation

extension URL {
    /// Attempt to construct a URL from the passed string and validate its components
    /// This will only allow http & https URLs with a full hostname
    init?(validatedString string: String) {
        guard let url = URL(string: string) else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.path = url.path
        
        guard let scheme = components.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return nil
        }
        guard components.host != nil else {
            return nil
        }
        
        if components.path.isEmpty {
            components.path = "/"
        }
        
        guard let validatedUrl = components.url else {
            return nil
        }
        
        self = validatedUrl
    }
    
    /// Check if URL is HTTP or HTTPs
    func isHTTP() -> Bool {
        return self.scheme == "http" || self.scheme == "https"
    }

    /// Add file name component to URL with extension
    /// - Returns: new URL
    func appendingFilename(name: String, ext: String) -> URL {
        var url = self
        url.appendPathComponent(name)
        url.appendPathExtension(ext)
        return url
    }

    /// Return path relative to some base
    /// Ensures the path does not have a leading slash.
    /// If URL does not start with base, returns nil.
    func relativizingPath(relativeTo base: URL) -> String? {
        // NOTE: it is important that you call `.relativizingPath`
        // WITHOUT first calling `url.deletePathExtension()`.
        // This is because `url.relativizingPath()` calls
        // `.standardizedFileURL` to resolve symlinks.
        // However, if there is not a file extension, `.standardizedFileURL`
        // will not recognize the URL as a file URL and will not
        // resolve symlinks.
        //
        // Instead, we relativize the path, get back a string, and then
        // use our custom String extension to remove the file extension.
        //
        // Issue: https://github.com/gordonbrander/subconscious/issues/57
        //
        // 2022-01-27 Gordon Brander
        // Standardize and absolutize paths to normalize them
        let path = self.standardizedFileURL.absoluteString
        let basePath = base.standardizedFileURL.absoluteString
        guard path.hasPrefix(basePath) else {
            return nil
        }
        // Return path without standardized percent encoding.
        guard
            let path = path.trimming(prefix: basePath).removingPercentEncoding
        else {
            return nil
        }
        return path.removingLeadingSlash()
    }
}

extension Sequence where Iterator.Element == URL {
    func withPathExtension(_ ext: String) -> [URL] {
        self.filter({url in url.pathExtension == ext})
    }
}
