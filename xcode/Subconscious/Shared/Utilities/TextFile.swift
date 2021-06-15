//
//  TextFile.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

/// An in-memory representation of a text file.
struct TextFile: CustomStringConvertible, Identifiable, Hashable, Equatable {
    var description: String { content }
    var id: URL { url }

    /// File URL
    let url: URL
    /// File content as string
    let content: String
    /// File last modified time
    let attributes: FileSync.FileFingerprint.Attributes

    init(
        url: URL,
        content: String,
        attributes: FileSync.FileFingerprint.Attributes
    ) {
        self.url = url
        self.content = content
        self.attributes = attributes
    }
    
    init(
        url: URL,
        content: String,
        modified: Date,
        size: Int
    ) {
        self.init(
            url: url,
            content: content,
            attributes: FileSync.FileFingerprint.Attributes(
                modified: modified,
                size: size
            )
        )
    }
    
    init?(
        url: URL,
        encoding: String.Encoding = .utf8,
        manager: FileManager = FileManager.default
    ) {
        guard
            let data = manager.contents(atPath: url.path),
            let content = String(data: data, encoding: .utf8),
            let attributes = FileSync.FileFingerprint.Attributes(
                url: url, manager: manager
            )
        else {
            return nil
        }
        self.init(url: url, content: content, attributes: attributes)
    }
}
