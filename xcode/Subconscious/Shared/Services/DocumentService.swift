//
//  FileService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/22/21.
//

import Foundation
import Combine

/// Service for interacting with user's documents
/// We use this as a service abstraction layer over the actual file system.
struct DocumentService {
    enum DocumentServiceError: Error {
        case url(message: String)
        case write(message: String)
    }

    private let fileManager = FileManager.default

    /// Get the URL for the user's document directory, if any.
    var documentDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    /// List all URLs for files in the user's document directory.
    /// Omits hidden files.
    private func listDocumentUrls() -> [URL] {
        if let dir = documentDirectory {
            let files = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            return files ?? []
        } else {
            return []
        }
    }

    private func listDocumentUrlsWithSuffix(suffix: String) -> [URL] {
        listDocumentUrls().filter({url in url.pathExtension == suffix})
    }

    /// List all Subtext URLs in the app's root directory
    func listSubtextUrls() -> [URL] {
        return listDocumentUrlsWithSuffix(suffix: "subtext")
    }

    /// Get URL for title. URL may or may not exist already.
    func urlForTitle(title: String) -> URL? {
        return documentDirectory?
            .appendingFilename(name: title, ext: "subtext")
    }
    
    /// Find and read SubconsciousDocument by title
    /// - Returns: `SubconsciousDocument` if one exists with that title.
    func read(url: URL) throws -> Future<SubconsciousDocument, Never> {
        Future { promise in
            let doc: SubconsciousDocument
            do {
                doc = try SubconsciousDocument(
                    title: url.stem,
                    markup: String(contentsOf: url, encoding: .utf8)
                )
            } catch {
                doc = SubconsciousDocument(
                    title: url.stem,
                    markup: ""
                )
            }
            promise(.success(doc))
        }
    }

    // FIXME: This is just serves up all documents right now
    func query(query: String) -> Future<[SubconsciousDocument], Never> {
        Future { promise in
            let urls = listSubtextUrls()
            let threads = urls.compactMap { url in
                try? SubconsciousDocument(
                    title: url.stem,
                    markup: String(contentsOf: url, encoding: .utf8)
                )
            }
            promise(.success(threads))
        }
    }
    
    func write(_ document: SubconsciousDocument) -> Future<Void, Never> {
        Future({ promise in
            if let url = urlForTitle(title: document.title) {
                do {
                    try String(document.content).write(
                        to: url,
                        atomically: true,
                        encoding: .utf8
                    )
                } catch {}
            }
        })
    }
}
