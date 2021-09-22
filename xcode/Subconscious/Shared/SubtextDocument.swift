//
//  SubtextDocument.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    /// Constant for our file type.
    /// Used by macOS and iOS to determine default editors, nice icons, etc.
    /// We base it on utf8PlainText.
    static let subtext = UTType(
        exportedAs: "com.subconscious.subtext",
        conformingTo: .utf8PlainText
    )
}

/// Type for subtext document
struct SubtextDocument: Hashable {
    var title: String
    var content: String

    /// Basic initializer
    init(
        title: String,
        content: String
    ) {
        self.title = title
        self.content = content
    }

    /// Derive title from content
    init(content: String) {
        self.title = Subtext3(content)
            .strip()
            .derivingTitle(fallback: AppEnvironment.untitled)
        self.content = content
    }

    /// File initializer
    init(url: URL) throws {
        self.title = url.stem
        self.content = try String(contentsOf: url, encoding: .utf8)
    }

    /// Write to URL, or overwrite existing file at URL
    func write(
        url: URL
    ) throws {
        try content.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}

/// A SubtextDocument together with a location for that document
struct SubtextDocumentLocation: Hashable, Identifiable {
    enum SubtextDocumentError: Error {
        case nonFileURL
    }

    static func findUniqueURL(
        at directory: URL,
        name: String,
        ext: String
    ) -> URL? {
        FileManager.default.findUniqueURL(
            at: directory,
            name: name,
            ext: ext
        )
    }

    /// Create new document
    static func new(
        directory: URL,
        document: SubtextDocument
    ) -> Self? {
        if let url = Self.findUniqueURL(
            at: directory,
            name: document.title,
            ext: "subtext"
        ) {
            return Self(url: url, document: document)
        }
        return nil
    }

    var url: URL
    var document: SubtextDocument
    var id: URL { url }

    init(
        url: URL,
        document: SubtextDocument
    ) {
        // Absolutize URL in order to allow it to function as an ID
        self.url = url.absoluteURL
        self.document = document
    }

    /// Open existing document
    init(url: URL) throws {
        // Absolutize URL in order to allow it to function as an ID
        self.url = url.absoluteURL
        self.document = try .init(url: url)
    }

    func write() throws {
        try document.write(url: url)
    }
}
