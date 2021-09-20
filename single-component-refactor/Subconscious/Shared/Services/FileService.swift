//
//  FileService.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import Foundation
import Combine

/// Service for interacting with document files
struct FileService {
    let documentUrl: URL

    init(documentURL: URL) {
        self.documentUrl = documentURL
    }

    /// List entry file URLs
    func list() -> AnyPublisher<[URL], Error> {
        CombineUtilities.async {
            try FileManager.default.contentsOfDirectory(
                at: documentUrl,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ).withPathExtension("subtext")
        }
    }

    /// Get fingerprints (URL, modified, size) for entry files
    func fingerprints() -> AnyPublisher<[FileFingerprint], Error> {
        list().map({ urls in
            urls.compactMap({ url in
                FileFingerprint(url: url)
            })
        }).eraseToAnyPublisher()
    }
}
