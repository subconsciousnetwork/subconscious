//
//  AppModel.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/12/21.
//

import Foundation
import Combine

final class AppModel: ObservableObject {
    @Published var liveQuery: String = "" {
        didSet {
            self.results = self.fetchResults()
        }
    }
    @Published var comittedQuery: String = "" {
        didSet {
            self.threads = self.fetchThreads()
        }
    }
    @Published var results: [Result] = []
    @Published var threads: [Thread] = []

    private func fetchResults() -> [Result] {
        return [
            Result.thread(
                ThreadResult(text: "If you have 70 notecards, you have a movie")
            ),
            Result.thread(
                ThreadResult(text: "Tenuki")
            ),
            Result.query(
                QueryResult(text: "Notecard")
            ),
            Result.create(
                CreateResult(text: "Notecard")
            ),
        ]
    }
    
    private func fetchThreads() -> [Thread] {
        return [
            Thread(
                id: UUID(),
                title: "Hello",
                blocks: [
                    Block.text(TextBlock(text: "I am a text block")),
                    Block.text(TextBlock(text: "I am also a text block")),
                    Block.heading(HeadingBlock(text: "Heading block")),
                    Block.text(TextBlock(text: "Some more text")),
                ]
            ),
            Thread(
                id: UUID(),
                title: "World",
                blocks: [
                    Block.text(TextBlock(text: "I am a text block")),
                    Block.text(TextBlock(text: "I am also a text block")),
                    Block.heading(HeadingBlock(text: "Heading block")),
                    Block.text(TextBlock(text: "Some more text")),
                ]
            ),
        ]
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
