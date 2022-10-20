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
            String(describing: headers[0].name),
            "Content-Type"
        )
        XCTAssertEqual(
            String(describing: headers[1].name),
            "Title"
        )
        XCTAssertEqual(
            headers[1].value,
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
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(
            headers[1].value,
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
            headers.count,
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
            headers.count,
            0
        )
        XCTAssertEqual(
            tape.rest,
            "Body text\n"
        )
    }
    
    func testHeadersGetFirst() throws {
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
    
    func testHeadersGetAll() throws {
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
        let values = headers.get(named: "content-type")
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0], "text/subtext")
        XCTAssertEqual(values[1], "text/plain")
    }
    
    func testHeadersReplaceA() throws {
        var headers = [
            Header(name: "Content-Type", value: "text/subtext"),
            Header(name: "Content-Type", value: "text/plain"),
            Header(name: "Title", value: "Floop the Pig"),
        ]
        headers.replace(
            name: "content-type",
            value: "application/json"
        )
        XCTAssertEqual(headers.count, 3)
        XCTAssertEqual(headers[0].value, "application/json")
    }
    
    func testHeadersReplaceB() throws {
        var headers = [
            Header(name: "Content-Type", value: "text/subtext"),
        ]
        headers.replace(name: "title", value: "Card Wars")
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers[1].value, "Card Wars")
    }
    
    func testHeadersRemoveDuplicates() throws {
        let headers = [
            Header(name: "Tags", value: "one,two,three"),
            Header(name: "Content-Type", value: "text/subtext"),
            Header(name: "Tags", value: "four,five,six"),
        ]
        let consolidated = headers.removeDuplicates()
        XCTAssertEqual(consolidated.count, 2)
        XCTAssertEqual(
            consolidated[0].value,
            "one,two,three",
            "keeps first header, and keeps ordering"
        )
        XCTAssertEqual(
            consolidated[1].value,
            "text/subtext",
            "preserves order of headers"
        )
    }
    
    /// Test Headers.merge.
    /// Ensure that it:
    /// - Merges headers
    /// - Keeps only the first header and drops dupes
    func testHeadersMerge() throws {
        let headers = [
            Header(name: "Tags", value: "one,two,three"),
            Header(name: "Content-Type", value: "text/subtext"),
            Header(name: "Tags", value: "four,five,six"),
        ]
        let other = [
            Header(name: "Content-Type", value: "text/subtext"),
            Header(name: "Tags", value: "a,b,c"),
            Header(name: "Featured", value: "true"),
        ]
        let merged = headers.merge(other)
        XCTAssertEqual(merged.count, 3)
        XCTAssertEqual(
            merged[0].value,
            "one,two,three",
            "keeps first header, and keeps ordering"
        )
        XCTAssertEqual(
            merged[1].value,
            "text/subtext",
            "Keeps first content-type"
        )
        XCTAssertEqual(
            merged[2].value,
            "true",
            "Drops duplicates, including dupes in original set"
        )
    }
    
    func testHeadersGetContentTypeA() throws {
        let headers = [
            Header(name: "Content-Type", value: "text/subtext"),
        ]
        let contentType = headers.contentType()
        XCTAssertEqual(contentType, "text/subtext", "Gets content type")
    }
    
    func testHeadersGetContentTypeB() throws {
        let headers = [
            Header(name: "Content-Type", value: "text/subtext"),
            Header(name: "Content-Type", value: "application/json"),
        ]
        let contentType = headers.contentType()
        XCTAssertEqual(
            contentType,
            "text/subtext",
            "Gets first content type header"
        )
    }
    
    func testHeadersSetContentType() throws {
        var headers = [
            Header(name: "Title", value: "Great Expectations"),
            Header(name: "Content-Type", value: "text/subtext"),
        ]
        headers.contentType("application/json")
        XCTAssertEqual(
            headers[1].value,
            "application/json",
            "Sets first content type header"
        )
    }
    
    func testHeadersModifiedRoundtrip() throws {
        var headers = Headers()
        let valueA = headers.modified()
        XCTAssertNil(valueA)
        let now = Date.now
        headers.modified(now)
        guard let date = headers.modified() else {
            XCTFail("Did not set date")
            return
        }
        let interval = now.timeIntervalSince(date)
        XCTAssert(interval < 1, "Date is set (we allow encoding lossiness up to second-precision)")
    }
    
    func testHeadersCreatedRoundtrip() throws {
        var headers = Headers()
        let valueA = headers.created()
        XCTAssertNil(valueA)
        let now = Date.now
        headers.created(now)
        guard let date = headers.created() else {
            XCTFail("Did not set date")
            return
        }
        let interval = now.timeIntervalSince(date)
        XCTAssert(interval < 1, "Date is set (we allow encoding lossiness up to second-precision)")
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
        let text = headers.text
        XCTAssertEqual(
            text,
            "Content-Type: text/subtext\nContent-Type: text/plain\nTitle: Floop the Pig\n\n",
            "Renders headers with trailing blank line"
        )
    }
}
