//
//  Tests_NLP.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 31/1/2024.
//

import XCTest
@testable import Subconscious
import NaturalLanguage

final class Tests_NLP: XCTestCase {
    func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.noun] // Focus on nouns and verbs

        var keywords = [String]()
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word, scheme: .lexicalClass,
            options: options
        ) { tag, tokenRange in
            if let tag = tag, tags.contains(tag) {
                let keyword = String(text[tokenRange])
                keywords.append(keyword)
            }
            return true
        }

        return keywords
    }

    func testKeywords() {
        // Example usage
        let text = """
        # Piano of the Dead

        Like Typing of the Dead except you have to use a MIDI controller and his the notes / chords that appear above each enemies head. Multi-player could be playing a multi-track piece together.

        Somewhat like /musical-speedrun
        """
        let keywords = extractKeywords(from: text)
        print(keywords)
    }
    
    func testClassifier() {
        
    }
}
