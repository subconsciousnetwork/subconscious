//
//  StoryStore.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/28/22.
//

import Foundation

struct StoryStore: StoreProtocol {
    typealias Key = Slug
    typealias Value = Story
    
    private var store: FileStore
    
    init(store: FileStore) {
        self.store = store
    }

    func read(_ slug: Slug) throws -> Story {
        try store.read(
            with: Story.from,
            key: slug.toPath(ContentType.story.ext)
        )
    }
    
    func write(_ slug: Slug, value: Story) throws {
        try store.write(
            with: Data.from,
            key: slug.toPath(ContentType.story.ext),
            value: value
        )
    }
    
    func remove(_ slug: Slug) throws {
        try store.remove(slug.toPath(ContentType.story.ext))
    }
    
    func list() throws -> some Sequence<Slug> {
        try store.list()
            .lazy
            .filter({ path in
                path.hasExtension(ContentType.story.ext)
            })
            .compactMap({ path in
                Slug(path.deletingPathExtension())
            })
    }

    func save() throws {
    }
}
