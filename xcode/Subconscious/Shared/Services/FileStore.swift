//
//  FileStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

enum FileStoreError: Error {
    case failReadAttribute(FileAttributeKey)
    case doesNotExist(String)
    case decodingError(String)
    case encodingError(String)
}

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
    func read(_ key: String) throws -> Data {
        let url = url(forKey: key)
        let data = try Data(contentsOf: url)
        return data
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
    func list() throws -> [String] {
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
    func info(_ key: String) throws -> FileInfo {
        let url = url(forKey: key)
        let attributes = try FileManager.default.attributesOfItem(
            atPath: url.path
        )
        guard let modified = attributes[.modificationDate] as? Date else {
            throw FileStoreError.failReadAttribute(.modificationDate)
        }
        guard let created = attributes[.creationDate] as? Date else {
            throw FileStoreError.failReadAttribute(.creationDate)
        }
        guard let size = attributes[.size] as? Int else {
            throw FileStoreError.failReadAttribute(.size)
        }
        return FileInfo(created: created, modified: modified, size: size)
    }
}
