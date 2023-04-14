//
//  FeedService.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/24/22.
//

import Foundation
import Combine

struct FeedService {
    private var geists: [String: Geist]

    init() {
        self.geists = [:]
    }

    /// Register a geist with FeedService
    mutating func register(name: String, geist: Geist) {
        self.geists[name] = geist
    }

    /// Generate new stories (upt to a maximum number)
    /// TODO: currently this is just a random selection.
    /// We should consider other approaches, including using a tracery grammar.
    /// Eventually, we want to do something based on follows.
    func generate(max: Int) -> AnyPublisher<[Story], Error> {
        DispatchQueue.global().future {
            let geists = geists.values
            var stories: [Story] = []
            for _ in 0..<max {
                let geist = geists.randomElement()
                if let story = geist?.ask(query: "") {
                    stories.append(story)
                }
            }
            return stories
        }
        .eraseToAnyPublisher()
    }
}
