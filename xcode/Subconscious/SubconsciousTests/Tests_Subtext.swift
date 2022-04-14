//
//  Tests_Subtext.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/11/22.
//

import XCTest
@testable import Subconscious

class Tests_Subtext: XCTestCase {
    func testHeadingParsing() throws {
        let markup = "# Some text"
        let dom = Subtext(markup: markup)

        guard case .heading(_) = dom.blocks[0] else {
            XCTFail("Expected heading")
            return
        }
    }

    func testQuoteParsing() throws {
        let markup = "> Some text"
        let dom = Subtext(markup: markup)

        guard case .quote(_, _) = dom.blocks[0] else {
            XCTFail("Expected quote")
            return
        }
    }

    func testListParsing() throws {
        let markup = "- Some text"
        let dom = Subtext(markup: markup)

        guard case .list(_, _) = dom.blocks[0] else {
            XCTFail("Expected list")
            return
        }
    }

    func testTextParsing() throws {
        let markup = "Some text"
        let dom = Subtext(markup: markup)

        guard case .text(_, _) = dom.blocks[0] else {
            XCTFail("Expected text")
            return
        }
    }

    func testEmptyParsing() throws {
        let markup = """
        
        Some text after an empty block
        """
        let dom = Subtext(markup: markup)

        let block = dom.blocks[0]
        guard case .empty = block else {
            XCTFail("Expected empty, got \(block)")
            return
        }
    }

    func testSpaceParsesAsTextNotEmpty() throws {
        let markup = """
         
        Some text after an empty block
        """
        let dom = Subtext(markup: markup)

        guard case .text(_, _) = dom.blocks[0] else {
            XCTFail("Expected text")
            return
        }
    }

    func testLinkParsing0() throws {
        let markup = "Some text with a http://example.com link"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "http://example.com",
            "Link parses successfully"
        )
    }

    func testLinkParsingHttps() throws {
        let markup = "Some text with a https://example.com link"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com",
            "HTTPS link parses successfully"
        )
    }

    func testLinkParsingQueryParams() throws {
        let markup = "Some text with a http://example.com?foo=bar&baz=bing link"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "http://example.com?foo=bar&baz=bing",
            "Link with query params parses successfully"
        )
    }

    func testLinkParsingTrailingPunctuation0() throws {
        let markup = "Some text with a https://example.com. Yes!"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com",
            "Link with trailing punctuation parses successfully"
        )
    }

    func testLinkParsingTrailingPunctuation1() throws {
        let markup = "Some text with a https://example.com! Yes!"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com",
            "Link with trailing punctuation parses successfully"
        )
    }

    func testLinkParsingTrailingPunctuation2() throws {
        let markup = "Some text with a https://example.com? Yes!"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com",
            "Link with trailing punctuation parses successfully"
        )
    }

    func testLinkParsingTrailingPunctuation3() throws {
        let markup = "Some text with a https://example.com, yes!"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com",
            "Link with trailing punctuation parses successfully"
        )
    }

    func testLinkParsingTrailingPunctuation4() throws {
        let markup = "Some text with a https://example.com; yes!"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com",
            "Link with trailing punctuation parses successfully"
        )
    }

    func testLinkParsingTrailingPunctuation5() throws {
        let markup = "Some text with a https://example.com( Yes!"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com",
            "Link with trailing punctuation parses successfully"
        )
    }

    func testLinkParsingTrailingSlash() throws {
        let markup = "Some text with a https://example.com/ Yes!"
        let dom = Subtext(markup: markup)

        guard case let .link(link) = dom.blocks[0].inline[0] else {
            XCTFail("Expected link")
            return
        }

        XCTAssertEqual(
            String(describing: link),
            "https://example.com/",
            "Link with trailing punctuation parses successfully"
        )
    }

    func testSlashlinkParsing0() throws {
        let markup = "Some text with a /slashlink."
        let dom = Subtext(markup: markup)

        guard case let .slashlink(slashlink) = dom.blocks[0].inline[0] else {
            XCTFail("Expected slashlink")
            return
        }

        XCTAssertEqual(
            String(describing: slashlink),
            "/slashlink",
            "Slashlink parses successfully"
        )
    }

    func testSlashlinkParsing1() throws {
        let markup = "/slashlink at the beginning."
        let dom = Subtext(markup: markup)

        guard case let .slashlink(slashlink) = dom.blocks[0].inline[0] else {
            XCTFail("Expected slashlink")
            return
        }

        XCTAssertEqual(
            String(describing: slashlink),
            "/slashlink",
            "Slashlink parses successfully"
        )
    }

    func testWikilinkParsing0() throws {
        let markup = """
        Let's test out some [[wikilinks]].
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[wikilinks]]",
            "Wikilink markup parses to wikilink"
        )
    }

    func testWikilinkParsing1() throws {
        let markup = """
        [[Wikilink]] leading the block.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[Wikilink]]",
            "Wikilink markup parses to wikilink"
        )
    }

    func testWikilinkParsing3() throws {
        let markup = """
        [[Wikilink]]! with some trailing punctuation.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks.get(0)?.inline.get(0)
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(String(describing: inline0))")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[Wikilink]]",
            "Wikilink markup parses to wikilink"
        )
    }

    func testWikilinkParsing4() throws {
        let markup = """
        Here's a[[wikilink]]embedded in some text.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks.get(0)?.inline.get(0)
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(String(describing: inline0))")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[wikilink]]",
            "Wikilink is detected when embedded in text"
        )
    }

    func testWikilinkParsingBrokenClosingBracket() throws {
        let markup = """
        Here's a [[wikilink]] followed by ]] in some text.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks.get(0)?.inline.get(0)
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(String(describing: inline0))")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[wikilink]]",
            "Wikilink closes at the first closing bracket"
        )
    }

    func testWikilinkParsingSpaceInBrackets() throws {
        let markup = """
        Here's a [[wikilink] ] except it's broken.
        """
        let dom = Subtext(markup: markup)
        XCTAssert(
            dom.blocks.get(0)?.inline.count == 0,
            "Broken wikilink with space in brackets is not parsed as wikilink"
        )
    }

    func testWikilinkParsingSpaceInBrackets2() throws {
        let markup = """
        Here's a [[wikilink] text] except it's broken.
        """
        let dom = Subtext(markup: markup)
        XCTAssert(
            dom.blocks.get(0)?.inline.count == 0,
            "Broken wikilink with space in brackets is not parsed as wikilink"
        )
    }

    func testWikilinkParsingBrokenOpenBracket() throws {
        let markup = """
        Here's a [[nonwikilink in some text.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks.get(0)?.inline.get(0)
        XCTAssertEqual(
            inline0,
            nil,
            "Wikilink requires closing bracket"
        )
    }

    func testWikilinkDoubleOpenBracket() throws {
        let markup = """
        Here's a [[ [[wikilink]] with an additional opening bracket preceding.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks.get(0)?.inline.get(0)
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(String(describing: inline0))")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[wikilink]]",
            "Wikilink requires closing bracket"
        )
    }

    func testWikilinkText() throws {
        let markup = """
        Let's test out a [[wikilink]].
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(inline0)")
            return
        }
        XCTAssertEqual(
            wikilink.text,
            "wikilink",
            "Wikilink text omits brackets"
        )
    }

    func testItalicParsing0() throws {
        let markup = """
        _Italics_ in the front
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .italic(italic) = inline0 else {
            XCTFail("Expected italic but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: italic),
            "_Italics_",
            "Italic markup parses to italic"
        )
    }

    func testItalicParsing1() throws {
        let markup = """
        Some _italic_ in the middle
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .italic(italic) = inline0 else {
            XCTFail("Expected italic but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: italic),
            "_italic_",
            "Italic markup parses to italic"
        )
    }

    func testItalicParsing2() throws {
        let markup = """
        Heres some_italic_embedded in the text
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .italic(italic) = inline0 else {
            XCTFail("Expected italic but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: italic),
            "_italic_",
            "Italic markup parses to italic"
        )
    }

    func testItalicParsing3() throws {
        let markup = """
        Here's some _italic_ with_ a stray tag in the text
        """
        let dom = Subtext(markup: markup)
        XCTAssertEqual(
            dom.blocks[0].inline.count,
            1,
            "Only one italic block detected"
        )
        let inline0 = dom.blocks[0].inline[0]
        guard case let .italic(italic) = inline0 else {
            XCTFail("Expected italic but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: italic),
            "_italic_",
            "Italic markup parses to italic"
        )
    }

    func testItalicText() throws {
        let markup = """
        Let's test out _italic_
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .italic(italic) = inline0 else {
            XCTFail("Expected italic but was \(inline0)")
            return
        }
        XCTAssertEqual(
            italic.text,
            "italic",
            "Italic text field omits markup"
        )
    }

    func testBoldParsing0() throws {
        let markup = """
        *Bold* in the front
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .bold(bold) = inline0 else {
            XCTFail("Expected bold but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: bold),
            "*Bold*",
            "Bold markup parses to bold"
        )
    }

    func testBoldParsing1() throws {
        let markup = """
        Some *bold* in the middle
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .bold(bold) = inline0 else {
            XCTFail("Expected bold but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: bold),
            "*bold*",
            "Bold markup parses to bold"
        )
    }

    func testBoldParsing2() throws {
        let markup = """
        Heres some*bold*embedded in the text
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .bold(bold) = inline0 else {
            XCTFail("Expected bold but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: bold),
            "*bold*",
            "Bold markup parses to bold"
        )
    }

    func testBoldParsing3() throws {
        let markup = """
        Here's some *bold* with* a stray tag in the text
        """
        let dom = Subtext(markup: markup)
        XCTAssertEqual(
            dom.blocks[0].inline.count,
            1,
            "Only one bold block detected"
        )
        let inline0 = dom.blocks[0].inline[0]
        guard case let .bold(bold) = inline0 else {
            XCTFail("Expected bold but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: bold),
            "*bold*",
            "Bold markup parses to bold"
        )
    }

    func testBoldText() throws {
        let markup = """
        Let's test out *bold*.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .bold(bold) = inline0 else {
            XCTFail("Expected bold but was \(inline0)")
            return
        }
        XCTAssertEqual(
            bold.text,
            "bold",
            "Bold text field omits markup"
        )
    }

    func testCodeParsing0() throws {
        let markup = """
        `Code` in the front
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .code(code) = inline0 else {
            XCTFail("Expected code but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: code),
            "`Code`",
            "Code markup parses to code"
        )
    }

    func testCodeParsing1() throws {
        let markup = """
        Some `code text` in the middle
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .code(code) = inline0 else {
            XCTFail("Expected code but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: code),
            "`code text`",
            "Code markup parses to code"
        )
    }

    func testCodeParsing2() throws {
        let markup = """
        Heres some`code`embedded in the text
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .code(code) = inline0 else {
            XCTFail("Expected code but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: code),
            "`code`",
            "Code markup parses to code"
        )
    }

    func testCodeParsing3() throws {
        let markup = """
        Here's some `code` with` a stray tag in the text
        """
        let dom = Subtext(markup: markup)
        XCTAssertEqual(
            dom.blocks[0].inline.count,
            1,
            "Only one code block detected"
        )
        let inline0 = dom.blocks[0].inline[0]
        guard case let .code(code) = inline0 else {
            XCTFail("Expected code but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: code),
            "`code`",
            "Code markup parses to code"
        )
    }

    func testCodeText() throws {
        let markup = """
        Let's test out `code`.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .code(code) = inline0 else {
            XCTFail("Expected code but was \(inline0)")
            return
        }
        XCTAssertEqual(
            code.text,
            "code",
            "Code text field omits markup"
        )
    }

    func testInlineCollisions0() throws {
        let markup = """
        Let's test out *bo_ld*_.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .bold(bold) = inline0 else {
            XCTFail("Expected bold but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: bold),
            "*bo_ld*",
            "Opening * parses until closing, * or backtracks"
        )
    }

    func testInlineCollisions2() throws {
        let markup = """
        Let's test out _it*al*ic_ly*.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .italic(italic) = inline0 else {
            XCTFail("Expected italic but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: italic),
            "_it*al*ic_",
            "Opening _ parses until closing, _ or backtracks"
        )
    }

    func testInlineCollisions3() throws {
        let markup = """
        Let's test out `_`it*al*ic_ly*.
        """
        let dom = Subtext(markup: markup)
        let block = dom.blocks[0]

        XCTAssertEqual(block.inline.count, 2, "Two inlines parsed")

        guard case let .code(code) = block.inline[0] else {
            XCTFail("Expected code")
            return
        }
        guard case let .bold(bold) = block.inline[1] else {
            XCTFail("Expected bold")
            return
        }

        XCTAssertEqual(
            String(describing: code),
            "`_`",
            "First inline is code"
        )

        XCTAssertEqual(
            String(describing: bold),
            "*al*",
            "Second inline is bold"
        )
    }
}
