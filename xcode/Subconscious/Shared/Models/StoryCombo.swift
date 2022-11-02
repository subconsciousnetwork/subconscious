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
            if story.entryA.slug < story.entryB.slug {
                return (story.entryA, story.entryB)
            } else {
                return (story.entryB, story.entryA)
            }
        })

        guard let link = EntryLink.init(
            title: "\(x.linkableTitle) x \(y.linkableTitle)"
        ) else {
            return nil
        }

        self.init(
            slug: link.slug,
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now, modified: Date.now,
                title: link.title,
                fileExtension: ContentType.subtext.fileExtension,
                other: [],
                body: """
                \(story.prompt)
                
                \(x.link.slug.toSlashlink())
                \(y.link.slug.toSlashlink())
                """
            )
        )
    }
}
