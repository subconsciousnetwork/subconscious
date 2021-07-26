//
//  FileSync.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/19/21.
//
import Foundation

struct FileSync {
    /// Given an array of URLs, get an array of FileFingerprints.
    /// If we can't read a fingerprint for the file, we filter it out of the list.
    static func readFileFingerprints(
        urls: [URL],
        with manager: FileManager = FileManager.default
    ) throws -> [FileFingerprint] {
        urls.compactMap({ url in
            FileFingerprint(url: url, with: manager)
        })
    }

    /// Given a set of FileFingerprints, return a dictionary, indexed by key
    static private func indexFileFingerprints(
        _ fingerprints: [FileFingerprint]
    ) -> Dictionary<URL, FileFingerprint> {
        Dictionary(
            fingerprints.map({ fingerprint in (fingerprint.url, fingerprint)}),
            uniquingKeysWith: { a, b in b }
        )
    }

    /// Changes are a left and right FileFingerprint?, zipped by id (file path).
    struct Change: Hashable, Equatable {
        /// Possible change statuses
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
                } else if left.attributes.modified > right.attributes.modified {
                    return .leftNewer
                } else if left.attributes.modified < right.attributes.modified {
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

        init?(left: FileFingerprint?, right: FileFingerprint?) {
            /// If we have a left and right fingerprint, but their IDs don't match, throw.
            if let l = left, let r = right {
                guard l.id == r.id else {
                    return nil
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
            if let change = Change(
                left: leftIndex[key],
                right: rightIndex[key]
            ) {
                changes.append(change)
            }
        }

        return changes
    }
}

extension FileSync.Change: CustomStringConvertible {
    var description: String {
        let url = (
            self.left?.url.absoluteString ??
            self.right?.url.absoluteString ??
            "nil"
        )
        return "Change(url: \(url), status: \(self.status))"
    }
}

extension FileSync.Change.Status: CustomStringConvertible {
    var description: String {
        switch self {
        case .leftOnly:
            return "leftOnly"
        case .leftNewer:
            return "leftNewer"
        case .rightOnly:
            return "rightOnly"
        case .rightNewer:
            return "rightNewer"
        case .conflict:
            return "conflict"
        case .same:
            return "same"
        }
    }
}
