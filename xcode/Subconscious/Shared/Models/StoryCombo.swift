//
//  StoryCombo.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 24/9/2022.
//

import Foundation

/// Story prompt model
struct StoryCombo: Hashable, Identifiable, Codable, CustomStringConvertible {
    var id = UUID()
    var prompt: String
    var entryA: EntryStub
    var entryB: EntryStub

    var description: String {
        """
        \(prompt)
        
        \(entryA)
        +
        \(entryB)
        """
    }
}

extension MemoEntry {
    init?(_ story: StoryCombo) {
        // Order by slug alpha
        let (x, y) = Func.block({
            if story.entryA.address < story.entryB.address {
                return (story.entryA, story.entryB)
            } else {
                return (story.entryB, story.entryA)
            }
        })

        let title = "\(x.address.slug) x \(y.address.slug)"
        guard let slug = Slug(formatting: title) else {
            return nil
        }
        let link = EntryLink(
            address: MemoAddress.local(slug),
            title: title
        )

        self.init(
            address: link.address,
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now, modified: Date.now,
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: """
                \(story.prompt)
                
                \(x.address.slug.toSlashlink().verbatim)
                \(y.address.slug.toSlashlink().verbatim)
                """
            )
        )
    }
}
