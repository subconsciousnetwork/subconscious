//
//  FileStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// Low-level facade over file system actions.
/// This store thinks in keys and Data.
/// Keys are path-like strings and are relative to the document directory.
///
/// Foundation is inconsistent in its treatment of paths.
/// Some older APIs use strings. Newer APIs tend to use URLs.
/// URLs have their own papercuts. They aren't stable because of the way
/// Foundation resolves them.
///
/// We use relative pathlike strings for our data so we can have a stable
/// identity and so we avoid exposing the root location.
/// This also brings us closer in line with the way Noosphere thinks about
/// paths (as string keys, essentially).
struct FileStore: StoreProtocol {
    private let fileManager = FileManager.default
    private let documentURL: URL
    
    init(documentURL: URL) {
        self.documentURL = documentURL
    }
    
    /// Get URL for key
    private func url(forKey key: String) -> URL {
        documentURL.appending(path: key)
    }
    
    /// Read bytes from key, if any.
    func read(_ key: String) -> Data? {
        let url = url(forKey: key)
        return try? Data(contentsOf: url)
    }
    
    /// Write file
    func write(_ key: String, value data: Data) throws {
        let url = url(forKey: key)
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try data.write(to: url)
    }
    
    /// Remove (delete) file
    func remove(_ key: String) throws {
        let url = url(forKey: key)
        try FileManager.default.removeItem(at: url)
    }
    
    func save() throws {
        // no-op
    }

    /// List all keys
    func list() -> [String] {
        guard let urls = FileManager.default.listFilesDeep(
            at: documentURL,
            includingPropertiesForKeys: []
        ) else {
            return []
        }
        return urls.compactMap({ url in
            url.relativizingPath(relativeTo: documentURL)
        })
    }

    /// Get info for file
    func info(_ key: String) -> FileInfo? {
        let url = url(forKey: key)
        guard let attributes = try? FileManager.default.attributesOfItem(
            atPath: url.path
        ) else {
            return nil
        }
        guard let modified = attributes[.modificationDate] as? Date else {
            return nil
        }
        guard let created = attributes[.creationDate] as? Date else {
            return nil
        }
        guard let size = attributes[.size] as? Int else {
            return nil
        }
        return FileInfo(created: created, modified: modified, size: size)
    }
}
