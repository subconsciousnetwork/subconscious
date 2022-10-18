//
//  Tests_Header.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/6/22.
//

import XCTest
@testable import Subconscious

class Tests_Header: XCTestCase {
    func testHeaderTitleNormalization() throws {
        let header = Header(name: "CONTENT TYPE", value: "text/subtext")
        XCTAssertEqual(header.name, "Content-Type")
    }

    func testHeaderValueNormalization() throws {
        let header = Header(name: "Title", value: "A title with newline\r\n")
        XCTAssertEqual(header.value, "A title with newline  ")
    }

    func testParseHeaderName() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let header = Header.parseName(&tape)
        XCTAssertEqual(
            header,
            "Content-Type"
        )
    }

    func testParseHeaderValue() throws {
        var tape = Tape("abcdefg\n")
        let value = Header.parseValue(&tape)
        XCTAssertEqual(
            value,
            "abcdefg"
        )
    }

    func testParseHeaderValueEOL() throws {
        var tape = Tape("abcdefg")
        let value = Header.parseValue(&tape)
        XCTAssertEqual(
            value,
            "abcdefg"
        )
    }

    func testHeaderParse() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let header = Header(&tape)
        XCTAssertNotNil(header)
        XCTAssertEqual(
            String(describing: header!.name),
            "Content-Type"
        )
    }

    func testHeaderParsedCleanValue() throws {
        var tape = Tape("Content-Type:    text/subtext\n")
        let header = Header(&tape)
        XCTAssertNotNil(header)
        XCTAssertEqual(
            header!.value,
            "text/subtext",
            "Header value trims leading spaces and trailing newline"
        )
    }

    func testParseHeaderMalformed() throws {
        let doc = "Malformed header You ganked my spirit walker\n"
        var tape = Tape(doc[...])
        let header = Header(&tape)
        XCTAssertEqual(
            header,
            nil
        )
    }

    func testParseInvalidHeaderName() throws {
        var tape = Tape("Content Type: text/subtext\n")
        let result = Header(&tape)
        XCTAssertEqual(
            result,
            nil
        )
    }

    func testParseHeaderEOL() throws {
        var tape = Tape("Content-Type: text/subtext")
        let result = Header(&tape)!
        XCTAssertEqual(
            result.value,
            "text/subtext"
        )
    }

    func testHeaderRender() throws {
        var tape = Tape("Content-Type: text/subtext\n")
        let header = Header(&tape)
        XCTAssertNotNil(header)
        XCTAssertEqual(
            String(describing: header!),
            "Content-Type: text/subtext\n",
            "Render returns valid header with trailing newline"
        )
    }

    /// Test name normalization. This behavior is not required, but is
    /// nice-to-have.
    func testHeaderRenderNormalized() throws {
        var tape = Tape("CONTENT-TYPE: text/subtext\n")
        let header = Header(&tape)
        XCTAssertNotNil(header)
        XCTAssertEqual(
            String(describing: header!),
            "Content-Type: text/subtext\n",
            "Render normalizes name"
        )
    }

    func testHeadersParser() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let headers = Headers(&tape)
        XCTAssertEqual(
            String(describing: headers.headers[0].name),
            "Content-Type"
        )
        XCTAssertEqual(
            String(describing: headers.headers[1].name),
            "Title"
        )
        XCTAssertEqual(
            headers.headers[1].value,
            "Floop the Pig"
        )
    }

    func testParseHeadersDropsEmptyLine() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Title: Floop the Pig
            
            Body text
            """
        )
        let headers = Headers(&tape)
        XCTAssertEqual(headers.headers.count, 2)
        XCTAssertEqual(
            headers.headers[1].value,
            "Floop the Pig",
            "Header value does not include newline"
        )
    }

    func testParseHeadersTapeDropsEmptyLine() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Title: Floop the Pig
            
            Body text
            """
        )
        _ = Headers(&tape)
        let next = tape.consume()
        XCTAssertEqual(
            next,
            "B",
            "Tape drops empty line after parsing headers"
        )
    }

    func testParseNoHeaders() throws {
        var tape = Tape("\nBody text\n")
        let headers = Headers(&tape)
        XCTAssertEqual(
            headers.headers.count,
            0
        )
        XCTAssertEqual(
            tape.rest,
            "Body text\n"
        )
    }

    func testParseMissingHeaders() throws {
        var tape = Tape("Body text\n")
        let headers = Headers(&tape)
        XCTAssertEqual(
            headers.headers.count,
            0
        )
        XCTAssertEqual(
            tape.rest,
            "Body text\n"
        )
    }

    func testHeadersFirst() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Content-Type: text/plain
            Title: Floop the Pig

            Body text
            """
        )
        let headers = Headers(&tape)
        let value = headers.get(first: "content-type")
        XCTAssertEqual(value, "text/subtext")
    }

    func testHeadersPuttingA() throws {
        let headers = Headers(
            headers: [
                Header(name: "Content-Type", value: "text/subtext"),
                Header(name: "Content-Type", value: "text/plain"),
                Header(name: "Title", value: "Floop the Pig"),
            ]
        )
        let next = headers.putting(
            name: "content-type",
            value: "application/json"
        )
        XCTAssertEqual(next.headers.count, 3)
        XCTAssertEqual(next.headers[0].value, "application/json")
    }

    func testHeadersPuttingB() throws {
        let headers = Headers(
            headers: [
                Header(name: "Content-Type", value: "text/subtext"),
            ]
        )
        let next = headers.putting(name: "title", value: "Card Wars")
        XCTAssertEqual(next.headers.count, 2)
        XCTAssertEqual(next.headers[1].value, "Card Wars")
    }

    func testHeadersConsolidating() throws {
        let headers = Headers(
            headers: [
                Header(name: "Tags", value: "one,two,three"),
                Header(name: "Content-Type", value: "text/subtext"),
                Header(name: "Tags", value: "four,five,six"),
            ]
        )
        let next = headers.consolidating()
        XCTAssertEqual(next.headers.count, 2)
        XCTAssertEqual(
            next.headers[0].value,
            "one,two,three,four-five,six",
            "consolidates, joining values with comma"
        )
        XCTAssertEqual(
            next.headers[1].value,
            "text/subtext",
            "preserves order of headers"
        )
    }

    func testHeadersGetContentTypeA() throws {
        let headers = Headers(
            headers: [
                Header(name: "Content-Type", value: "text/subtext"),
            ]
        )
        let contentType = headers.contentType()
        XCTAssertEqual(contentType, "text/subtext", "Gets content type")
    }

    func testHeadersGetContentTypeB() throws {
        let headers = Headers(
            headers: [
                Header(name: "Content-Type", value: "text/subtext"),
                Header(name: "Content-Type", value: "application/json"),
            ]
        )
        let contentType = headers.contentType()
        XCTAssertEqual(
            contentType,
            "text/subtext",
            "Gets first content type header"
        )
    }

    func testHeadersSetContentType() throws {
        let headers = Headers(
            headers: [
                Header(name: "Title", value: "Great Expectations"),
                Header(name: "Content-Type", value: "text/subtext"),
            ]
        )
        let next = headers.contentType("application/json")
        XCTAssertEqual(
            next.headers[0].value,
            "application/json",
            "Sets first content type header"
        )
    }

    func testHeadersModifiedRoundtrip() throws {
        let a = Headers(
            headers: []
        )
        let valueA = a.modified()
        XCTAssertNil(valueA)
        let now = Date.now
        let nowString = String.from(now)
        let b = a.modified(now)
        let valueB = b.get(first: "modified")
        XCTAssertEqual(valueB, nowString, "Saves header value")
        XCTAssertEqual(b.modified(), now, "Gets header value")
    }

    func testHeadersCreatedRoundtrip() throws {
        let a = Headers(
            headers: []
        )
        let valueA = a.created()
        XCTAssertNil(valueA)
        let now = Date.now
        let nowString = String.from(now)
        let b = a.created(now)
        let valueB = b.get(first: "created")
        XCTAssertEqual(valueB, nowString, "Saves header value")
        XCTAssertEqual(b.created(), now, "Gets header value")
    }

    func testHeadersDescription() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Content-Type: text/plain
            Title: Floop the Pig

            Body text
            """
        )
        let headers = Headers(&tape)
        let text = String(describing: headers)
        XCTAssertEqual(
            text,
            "Content-Type: text/subtext\nContent-Type: text/plain\nTitle: Floop the Pig\n\n",
            "Renders headers with trailing blank line"
        )
    }

    func testHeaderIndexFirstWins() throws {
        let headers = Headers(
            markup: """
            content-type: text/subtext
            Content-Type: text/javascript
            """
        )
        let index = HeaderIndex(headers)
        XCTAssertEqual(
            index["Content-Type"],
            "text/subtext"
        )
    }

    func testHeaderIndexSubscriptNormalization() throws {
        var index = HeaderIndex()
        index["title"] = "Kosmos"
        index["content type"] = "text/subtext"
        index["absurd\n   HEADER"] = "nonsense"
        index["Valid-Header"] = "Content with newline\r\n"
        XCTAssertEqual(
            index["TITLE"],
            "Kosmos",
            "Subscript normalizes keys when getting"
        )
        XCTAssertEqual(
            index.index["Title"],
            "Kosmos",
            "Subscript normalizes keys when setting"
        )
        XCTAssertEqual(
            index.index["Content-Type"],
            "text/subtext",
            "Subscript replaces spaces with dashes"
        )
        XCTAssertEqual(
            index.index["Absurd----Header"],
            "nonsense",
            "Subscript replaces whitespace with dashes"
        )
        XCTAssertEqual(
            index.index["Valid-Header"],
            "Content with newline  ",
            "Subscript replaces whitespace with dashes"
        )
    }

    func testHeaderIndexDescription() throws {
        let index = HeaderIndex(
            [
                Header(name: "content-type", value: "text/subtext"),
                Header(name: "title", value: "Gliding O'er All"),
            ]
        )
        XCTAssertEqual(
            String(describing: index),
            "Content-Type: text/subtext\nTitle: Gliding O'er All\n\n",
            "Index renders to correctly formatted header block"
        )
    }

    func testHeaderIndexSetDefault() throws {
        var index = HeaderIndex(
            [
                Header(name: "content-type", value: "text/subtext"),
            ]
        )
        let contentType = index.setDefault(
            name: "Content-Type",
            value: "fail"
        )
        let author = index.setDefault(
            name: "author",
            value: "Walt Whitman"
        )
        XCTAssertEqual(
            contentType,
            "text/subtext",
            "Returns existing value for existing headers"
        )
        XCTAssertEqual(
            author,
            "Walt Whitman",
            "Returns default value for headers that do not exist"
        )
        XCTAssertEqual(
            index.index["Content-Type"],
            "text/subtext",
            "setDefault does not override existing headers"
        )
        XCTAssertEqual(
            index.index["Author"],
            "Walt Whitman",
            "setDefault sets when no header with that name is present"
        )
    }

    func testHeaderIndexMerge() throws {
        let a = HeaderIndex(
            [
                Header(name: "content-type", value: "text/subtext"),
                Header(name: "title", value: "Leaves of Grass"),
            ]
        )
        let b = HeaderIndex(
            [
                Header(name: "content-type", value: "text/subtext"),
                Header(name: "title", value: "Wrong title"),
                Header(name: "author", value: "Walt Whitman"),
            ]
        )
        let c = a.merge(b)
        XCTAssertEqual(
            c.index.count,
            3,
            "Merge results in correct number of headers"
        )
        XCTAssertEqual(
            c["content-type"],
            "text/subtext"
        )
        XCTAssertEqual(
            c["title"],
            "Leaves of Grass",
            "Does not overwrite old headers (self wins)"
        )
        XCTAssertEqual(
            c["author"],
            "Walt Whitman",
            "Merges in new headers"
        )
    }
}
