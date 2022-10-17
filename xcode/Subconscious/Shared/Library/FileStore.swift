//
//  FileStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

enum FileStoreError: Error {
    case contentTypeError(String)
    case decodingError(String)
    case encodingError(String)
}

/// Basic facade over file system actions.
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
struct FileStore {
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
    func write(_ key: String, data: Data) throws {
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
}

extension FileStore {
    /// Read with a failable decoding function
    /// Our codebase defines a number of `DataType.from` static methods
    /// that can be composed to decode the data type you need.
    func read<T>(
        with decode: (Data) -> T?,
        key: String
    ) throws -> T {
        let data = try read(key)
        guard let value = decode(data) else {
            throw FileStoreError.decodingError("Failed to decode data")
        }
        return value
    }
    
    /// Write with a failable encoding function
    /// Our codebase defines a number of `DataType.from` static methods
    /// that can be composed to encode the data type you need.
    func write<T>(
        with encode: (T) -> Data?,
        key: String,
        value: T
    ) throws {
        guard let data = encode(value) else {
            throw FileStoreError.encodingError("Could not encode data")
        }
        try write(key, data: data)
    }
}
