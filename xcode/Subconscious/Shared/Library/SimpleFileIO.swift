//
//  SimpleFileIO.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/2/22.
//

import Foundation

/// Presents a high-level minimal IO interface
/// This minimal surface area reduces our interaction with the file system
/// and is easier to mock for testing.
protocol SimpleFileIOProtocol {
    /// Get the URL of the documents directory
    func documentsDirectoryURL() -> URL?
    /// Get the URL of the application support directory
    func applicationSupportURL() -> URL?
    /// Get the URL of a temporary directory
    func temporaryDirectoryURL(appropriateFor: URL?) -> URL?
    /// Check of a file exists
    func exists(at: URL) -> Bool
    /// Read data from a file
    func read(at: URL) -> Data?
    /// Write data to a file
    func write(to: URL, data: Data) throws
    /// Remove a file
    func remove(at: URL) throws
    /// Move a file
    func move(at: URL, to: URL) throws
}

extension SimpleFileIOProtocol {
    func read(at url: URL, encoding: String.Encoding) -> String? {
        guard let data = read(at: url) else {
            return nil
        }
        return String(data: data, encoding: encoding)
    }

    func write(to url: URL, string: String, encoding: String.Encoding) throws {
        let data = try string.data(using: encoding).unwrap()
        try write(to: url, data: data)
    }
}

/// Wraps FileManager to expose a `SimpleFileIO` interface
struct SimpleFileIO: SimpleFileIOProtocol {
    private let fileManager = FileManager.default

    func documentsDirectoryURL() -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func applicationSupportURL() -> URL? {
        try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    func temporaryDirectoryURL(appropriateFor destinationURL: URL?) -> URL? {
        try? fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: destinationURL,
            create: true
        )
    }

    func exists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.absoluteString)
    }

    /// Read `data` from `url`.
    func read(at url: URL) -> Data? {
        fileManager.contents(atPath: url.absoluteString)
    }

    /// Write `data` to `url`. Creates intermediate directories if needed.
    /// Writes atomically.
    func write(to url: URL, data: Data) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try data.write(to: url, options: .atomic)
    }
    
    func remove(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    func move(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.moveItem(at: srcURL, to: dstURL)
    }
}

/// Mocking class for SimpleFileIOProtocol.
/// Does not touch file system. Instead keeps a Dictionary of URL to data.
/// Also records history of mutation calls, which is useful for testing order
/// of mutations.
class MockFileIO: SimpleFileIOProtocol {
    enum MockFileIOError: Error {
        case FileDoesNotExist
    }

    enum Event: Hashable {
        case write(url: URL)
        case remove(url: URL)
        case move(from: URL, to: URL)
    }

    private let fileManager = FileManager.default
    private var files: Dictionary<URL, Data> = [:]
    private(set) var history: [Event] = []

    func documentsDirectoryURL() -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func applicationSupportURL() -> URL? {
        try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
    }

    func temporaryDirectoryURL(appropriateFor destinationURL: URL?) -> URL? {
        try? fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: destinationURL,
            create: false
        )
    }

    func exists(at url: URL) -> Bool {
        files[url] != nil
    }

    /// Read `data` from `url`.
    func read(at url: URL) -> Data? {
        files[url]
    }

    /// Write `data` to `url`. Creates intermediate directories if needed.
    /// Writes atomically.
    func write(to url: URL, data: Data) throws {
        history.append(.write(url: url))
        files[url] = data
    }
    
    func remove(at url: URL) throws {
        history.append(.remove(url: url))
        files[url] = nil
    }
    
    func move(at srcURL: URL, to dstURL: URL) throws {
        guard files[srcURL] != nil else {
            throw MockFileIOError.FileDoesNotExist
        }
        history.append(.move(from: srcURL, to: dstURL))
        files[dstURL] = files[srcURL]
        files[srcURL] = nil
    }
}
