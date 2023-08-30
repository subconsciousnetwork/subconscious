//
//  BlockEditorTranscludeModel.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/30/23.
//
import Foundation

extension BlockEditor {
    struct TranscludeModel: Hashable, Identifiable {
        var id = UUID()
        var address: Slashlink
        var excerpt: String
        var modified: Date
        var author: UserProfile?
    }
}

extension EntryStub {
    /// Convert to `TranscludeModel` used in block editor.
    func toTranscludeModel() -> BlockEditor.TranscludeModel {
        BlockEditor.TranscludeModel(
            address: address,
            excerpt: excerpt,
            modified: modified
        )
    }
}
