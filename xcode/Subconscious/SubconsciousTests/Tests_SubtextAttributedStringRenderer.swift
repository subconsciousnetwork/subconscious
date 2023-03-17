//
//  Tests_SubtextAttributedStringRenderer.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/8/23.
//

import XCTest
@testable import Subconscious

final class Tests_SubtextAttributedStringRendererToURL: XCTestCase {
    func testSubSlashlinkToURL() throws {
        let link = SubSlashlinkLink(
            slashlink: Slashlink("@here/lo-and-behold")!,
            text: "Lo! And Behold"
        )
        
        guard let url = link.toURL() else {
            XCTFail("Failed to construct URL from link")
            return
        }
        
        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            XCTFail("Failed to parse URL components")
            return
        }
        
        XCTAssertEqual(components.scheme, "sub")
        XCTAssertEqual(components.host, "slashlink")
        XCTAssertEqual(
            components.firstQueryValueWhere(name: "slashlink"),
            "@here/lo-and-behold"
        )
        XCTAssertEqual(
            components.firstQueryValueWhere(name: "text"),
            "Lo! And Behold"
        )
    }
    
    func testSubSlashlinkFromURL() throws {
        let url = URL(string: "sub://slashlink?slashlink=@foo/bar&text=Bar")!
        
        guard let link = url.toSubSlashlinkURL() else {
            XCTFail("Failed to construct SubSlashlinkURL from URL")
            return
        }
        
        XCTAssertEqual(link.slashlink.description, "@foo/bar")
        XCTAssertEqual(link.text, "Bar")
    }
    
    func testSubSlashlinkFallbackWithText() throws {
        let link = SubSlashlinkLink(
            slashlink: Slashlink("@here/lo-and-behold")!,
            text: "Lo! And Behold"
        )
        
        XCTAssertEqual(link.fallback, "Lo! And Behold")
    }
    
    func testSubSlashlinkFallbackWithoutText() throws {
        let link = SubSlashlinkLink(
            slashlink: Slashlink("@here/lo-and-behold")!,
            text: nil
        )
        
        XCTAssertEqual(link.fallback, "Lo and behold")
    }
    
    func testPerformance() throws {
        let renderer = SubtextAttributedStringRenderer(bodySize: 17)
        let attributedString = NSMutableAttributedString(
            string: """
            Recombinant processes expand the [[adjacent possible]].
            
            https://overcast.fm/+UtNTuX9Ms/21:54
            
            Related: [[Sara Walker]], [[Stuart Kauffman]] [[SFI]], [[Assembly Theory]], [[Emergence comes from alphabets]], [[Alphabet]]
            
            # Mentioned Papers
            
            - Intelligence as a planetary scale process by Adam Frank, David Grinspoon & [[Sara Walker]]
            - [[The Algorithmic Origins of Life]] by Sara Imari Walker & Paul C. W. Davies
            - *Beyond prebiotic chemistry*: What dynamic network properties allow the emergence of life? by Leroy Cronin & Sara Walker /emergence-of-life
            - Identifying molecules as biosignatures with [[assembly theory]] and mass spectrometry by Stuart Marshall, Cole Mathis, Emma Carrick, Graham Keenan, Geoffrey Cooper, Heather Graham, Matthew Craven, Piotr Gromski, Douglas Moore, Sara Walker & Leroy Cronin
            - _Assembly Theory Explains and Quantifies the Emergence of Selection and Evolution_ by Abhishek Sharma, Dániel Czégel, Michael Lachmann, Christopher Kempes, [[Sara Walker]], Leroy Cronin
            - _Quantum Non-Barking Dogs_ by [[Sara Imari Walker]], Paul C. W. Davies, Prasant Samantray, Yakir Aharonov
            - _The Multiple Paths to Multiple Life_ by Christopher P. Kempes & [[David C. Krakauer]]
            
            # Other Related Videos & Writing
            
            - SFI Seminar - _Why Black Holes Eat Information_ by Vijay Balasubramanian
            - _Major Transitions in Planetary Evolution_ by Hikaru Furukawa and Sara Imari Walker
            - 2022 Community Lecture: “Recognizing The Alien in Us” by [[Sara Walker]]
            - Sara Walker and Lee Cronin: The Alien Debate on The Lex Fridman Show
            - If Cancer Were Easy, Every Cell Would Do It. SFI Press Release on work by Michael Lachmann
            - [[The Ministry for The Future]] by [[Kim Stanley Robinson]]
            - Re: Wheeler’s delayed choice experiment
            - On the SFI “Exploring Life’s Origins” Research Project
            - Complexity Explorer’s Origins of Life Free Open Online Course
            - Chiara Marletto on Constructor Theory
            - Simon Saunders, Philosopher of Physics at Oxford

            # Related SFI Podcast Episodes

            - Complexity 2 - The Origins of Life: David Krakauer, Sarah Maurer, and Chris Kempes at InterPlanetary Festival 2019
            - Complexity 8 - Olivia Judson on Major Energy Transitions in Evolutionary History
            - Complexity 17 - Chris Kempes on The Physical Constraints on Life & Evolution
            - Complexity 40 - The Information Theory of Biology & Origins of Life with Sara Imari Walker (Big Biology Podcast Crossover)
            - Complexity 41 - Natalie Grefenstette on Agnostic Biosignature Detection
            - Complexity 68 - W. Brian Arthur on Economics in Nouns & Verbs (Part 1)
            - Complexity 80 - Mingzhen Lu on The Evolution of Root Systems & Biogeochemical Cycling
            - Alien Crash Site 015 - Cole Mathis
            - Alien Crash Site 019 - Heather Graham
            - Alien Crash Site 020 - Chris Kempes
            - Alien Crash Site 021 - Natalie Grefenstette

            # Related notes
            
            [[SFI]]
            
            @sfi/podcast
            """
        )
        // Measure performance of render
        self.measure {
            _ = renderer.renderAttributesOf(attributedString)
        }
    }
}
