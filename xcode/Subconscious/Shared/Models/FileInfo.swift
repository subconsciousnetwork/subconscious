//
//  FileInfo.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/26/22.
//

import Foundation

/// A struct holding basic information about the file.
/// Equality can be used as a cheap way to check for mutation.
public struct FileInfo: Hashable, Equatable {
    var created: Date
    var modified: Date
    var size: Int
}

extension FileFingerprint.Attributes {
    init(_ info: FileInfo) {
        self.init(
            // Round to nearest second
            modified: Int(info.modified.timeIntervalSince1970),
            size: info.size
        )
    }
}

extension FileFingerprint {
    init(slug: Slug, info: FileInfo) {
        self.init(slug: slug, attributes: Attributes(info))
    }
}
