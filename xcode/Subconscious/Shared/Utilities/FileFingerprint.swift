//
//  FileFingerprint.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/16/21.
//

import Foundation

/// Fingerprint a file with a combination of file path, modified date, and file size.
/// Useful as an signal for file change when syncing.
///
/// This isn't perfect. You can't really know unless you do a checksum, but it is a fast good-enough
/// heuristic for simple cases.
///
/// This is the same strategy rsync uses when not doing full checksums.
struct FileFingerprint: Hashable, Equatable, Identifiable {
    /// File modified date and size.
    struct Attributes: Hashable, Equatable {
        let modified: Date
        let size: Int

        init(modified: Date, size: Int) {
            self.modified = modified
            self.size = size
        }
        
        init?(url: URL, manager: FileManager = .default) {
            guard
                let attr = try? manager.attributesOfItem(atPath: url.path),
                let modified = attr[FileAttributeKey.modificationDate] as? Date,
                let size = attr[FileAttributeKey.size] as? Int
            else {
                return nil
            }
            self.init(modified: modified, size: size)
        }
    }
    
    var id: String { self.url.path }
    let url: URL
    let attributes: Attributes

    init(url: URL, attributes: Attributes) {
        self.url = url.standardized.absoluteURL
        self.attributes = attributes
    }

    init(url: URL, modified: Date, size: Int) {
        self.init(
            url: url,
            attributes: Attributes(
                modified: modified,
                size: size
            )
        )
    }
    
    init?(
        url: URL,
        with manager: FileManager = FileManager.default
    ) {
        if let attributes = Attributes(url: url, manager: manager) {
            self.init(
                url: url,
                attributes: attributes
            )
        } else {
            return nil
        }
    }
}
