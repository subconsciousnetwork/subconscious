//
//  ChangeCheck.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/19/21.
//
import Foundation

struct ChangeCheck {
    typealias Path = String

    /// Fingerprint a file revision with a combination of file path, modified date, and file size.
    /// Useful as an signal for file change when syncing.
    ///
    /// This isn't perfect. You can't really know unless you do a checksum, but its a fast good-enough
    /// heuristics for simple cases.
    ///
    /// This is the same strategy rsync uses when not doing full checksums.
    struct FileFingerprint: Hashable, Equatable, Identifiable {
        var id: Path { self.path }
        let path: Path
        let modified: Date
        let size: Int
    }
    
    /// Get a FileChangeFingerprint for a given URL
    static func readFileFingerprint(
        with manager: FileManager,
        url: URL
    ) -> FileFingerprint? {
        do {
            let attr = try manager.attributesOfItem(atPath: url.path)
            if let modified = attr[FileAttributeKey.modificationDate] as? Date,
               let size = attr[FileAttributeKey.size] as? Int {
                return FileFingerprint(
                    path: url.path,
                    modified: modified,
                    size: size
                )
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    /// Given an array of URLs, get an array of FileFingerprints.
    /// If we can't read a fingerprint for the file, we filter it out of the list.
    static func readFileFingerprints(
        with manager: FileManager,
        urls: [URL]
    ) -> [FileFingerprint] {
        urls.compactMap({ url in
            readFileFingerprint(
                with: manager,
                url: url
            )
        })
    }

    /// Given a set of FileFingerprints, return a dictionary, indexed by key
    static private func indexFileFingerprints(
        _ fingerprints: [FileFingerprint]
    ) -> Dictionary<Path, FileFingerprint> {
        Dictionary(
            fingerprints.map({ fingerprint in (fingerprint.id, fingerprint)}),
            uniquingKeysWith: { a, b in b }
        )
    }

    /// Changes are a left and right FileFingerprint?, zipped by id (file path).
    struct Change: Hashable, Equatable {
        enum ChangeError: Error {
            case nonMatchingIdError
        }

        enum Status {
            case leftOnly
            case rightOnly
            case leftNewer
            case rightNewer
            case same
            case conflict
        }
        
        var status: Status {
            if let left = self.left, let right = self.right {
                if left == right {
                    return .same
                } else if left.modified > right.modified {
                    return .leftNewer
                } else if left.modified < right.modified {
                    return .rightNewer
                /// Left and right have the same modified time, but a different size
                } else {
                    return .conflict
                }
            } else if left != nil {
                return .leftOnly
            } else {
                return .rightOnly
            }
        }
        
        let left: FileFingerprint?
        let right: FileFingerprint?

        init(left: FileFingerprint?, right: FileFingerprint?) throws {
            /// If we have a left and right fingerprint, but their IDs don't match, throw.
            if let l = left, let r = right {
                guard l.id == r.id else {
                    throw ChangeError.nonMatchingIdError
                }
            }
            self.left = left
            self.right = right
        }
    }
    
    /// Given a left and right set of FileFingerprints, returns a set of Changes.
    static func calcChanges(
        left: [FileFingerprint],
        right: [FileFingerprint]
    ) -> [Change] {
        let leftIndex = indexFileFingerprints(left)
        let rightIndex = indexFileFingerprints(right)
        let allKeys = Set(leftIndex.keys).union(rightIndex.keys)

        var changes: [Change] = []
        for key in allKeys {
            do {
                changes.append(
                    try Change(
                        left: leftIndex[key],
                        right: rightIndex[key]
                    )
                )
            } catch {}
        }

        return changes
    }
}
