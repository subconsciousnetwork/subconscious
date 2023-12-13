//
//  BlockEditorRelatedModel.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/30/23.
//

import Foundation

extension BlockEditor {
    /// A collection of related notes
    struct RelatedModel: Hashable, Identifiable {
        var id = UUID()
        var related: [EntryStub] = []
    }
}

extension BlockEditor {
    enum RelatedAction {
        case activateLink(URL)
        case requestTransclude(EntryStub)
        case requestLink(Peer, SubSlashlinkLink)
    }
}
