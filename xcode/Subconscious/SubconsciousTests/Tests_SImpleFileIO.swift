//
//  Tests_SImpleFileIO.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/3/22.
//

import XCTest
@testable import Subconscious

class Tests_SImpleFileIO: XCTestCase {
    func testMockFileIOWriteReadRoundtrip() throws {
        let files = MockFileIO()
        guard let documents = files.documentsDirectoryURL() else {
            XCTFail("Failed to get documents directory")
            return
        }
        let fileURL = documents.appendingPathComponent("example.txt")
        try files.write(to: fileURL, string: "Example", encoding: .utf8)
        let content = files.read(at: fileURL, encoding: .utf8)
        XCTAssertEqual(
            content,
            "Example"
        )
    }
}
