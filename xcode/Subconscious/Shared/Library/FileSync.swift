//
//  FileSync.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/19/21.
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
        /// Modified time on file, stored as Unix Timestamp Integer (rounded to the nearest second)
        /// We were previously getting what appeared to be rounding precision errors
        /// when serializing datetimes as ISO strings using .
        ///
        /// Additionally, file timestamps precision is limited to:
        /// 1 second for EXT3
        /// 1 microsecond for UFS
        /// 1 nanosecond for EXT4
        ///
        /// To-the-nearest-second precision is fine for the purpose of comparing changes, and
        /// handwaves away these issues.
        ///
        /// 2021-07-26 Gordon Brander
        let modified: Int
        let size: Int

        /// Get modified time as Date instance
        var modifiedDate: Date {
            Date(timeIntervalSince1970: Double(modified))
        }

        init(modified: Date, size: Int) {
            self.modified = Int(modified.timeIntervalSince1970)
            self.size = size
        }

        init?(url: URL) {
            guard
                let attr = try? FileManager.default
                    .attributesOfItem(atPath: url.path),
                let modified = attr[FileAttributeKey.modificationDate] as? Date,
                let size = attr[FileAttributeKey.size] as? Int
            else {
                return nil
            }
            self.init(modified: modified, size: size)
        }
    }

    var id: Slug { self.slug }
    let slug: Slug
    let attributes: Attributes

    init(slug: Slug, attributes: Attributes) {
        self.slug = slug
        self.attributes = attributes
    }

    init(slug: Slug, modified: Date, size: Int) {
        self.init(
            slug: slug,
            attributes: Attributes(
                modified: modified,
                size: size
            )
        )
    }

    init(slug: Slug, modified: Date, text: String) {
        self.init(
            slug: slug,
            attributes: Attributes(
                modified: modified,
                size: text.lengthOfBytes(using: .utf8)
            )
        )
    }

    init?(
        url: URL,
        relativeTo base: URL
    ) {
        if
            let slug = Slug(url: url, relativeTo: base),
            let attributes = Attributes(url: url)
        {
            self.init(
                slug: slug,
                attributes: attributes
            )
        } else {
            return nil
        }
    }
}

enum FileFingerprintChange: Hashable, Equatable {
    case leftOnly(`left`: FileFingerprint)
    case rightOnly(`right`: FileFingerprint)
    case leftNewer(`left`: FileFingerprint, `right`: FileFingerprint)
    case rightNewer(`left`: FileFingerprint, `right`: FileFingerprint)
    case same(`left`: FileFingerprint, `right`: FileFingerprint)
    case conflict(`left`: FileFingerprint, `right`: FileFingerprint)

    static func create(
        left: FileFingerprint?,
        right: FileFingerprint?
    ) -> Self? {
        if
            let left = left,
            let right = right
        {
            if left.id != right.id {
                return nil
            } else if left == right {
                return .same(left: left, right: right)
            } else if left.attributes.modified > right.attributes.modified {
                return .leftNewer(left: left, right: right)
            } else if left.attributes.modified < right.attributes.modified {
                return .rightNewer(left: left, right: right)
            /// Left and right have the same modified time, but a different size
            } else {
                return .conflict(left: left, right: right)
            }
        } else if let left = left {
            return .leftOnly(left: left)
        } else if let right = right {
            return .rightOnly(right: right)
        }
        return nil
    }
}

struct FileSync {
    /// Given an array of URLs, get an array of FileFingerprints.
    /// If we can't read a fingerprint for the file, we filter it out of the list.
    static func readFileFingerprints(
        directory: URL,
        ext: String
    ) -> [FileFingerprint]? {
        FileManager.default.listFilesDeep(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )?
        .withPathExtension(ext)
        .compactMap({ url in
            FileFingerprint(url: url, relativeTo: directory)
        })
    }

    /// Given a set of FileFingerprints, return a dictionary, indexed by key
    static private func indexFileFingerprints(
        _ fingerprints: [FileFingerprint]
    ) -> Dictionary<Slug, FileFingerprint> {
        Dictionary(
            fingerprints.map({ fingerprint in (fingerprint.id, fingerprint)}),
            uniquingKeysWith: { a, b in b }
        )
    }

    /// Given a left and right set of FileFingerprints, returns a set of Changes.
    static func calcChanges(
        left: [FileFingerprint],
        right: [FileFingerprint]
    ) -> [FileFingerprintChange] {
        let leftIndex = indexFileFingerprints(left)
        let rightIndex = indexFileFingerprints(right)
        let allKeys = Set(leftIndex.keys).union(rightIndex.keys)

        var changes: [FileFingerprintChange] = []
        for key in allKeys {
            if let change = FileFingerprintChange.create(
                left: leftIndex[key],
                right: rightIndex[key]
            ) {
                changes.append(change)
            }
        }

        return changes
    }
}
