//
//  Tests_SimpleFileIO.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/3/22.
//

import XCTest
@testable import Subconscious

class Tests_SimpleFileIO: XCTestCase {
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

    func testExists() throws {
        let files = MockFileIO()
        guard let documents = files.documentsDirectoryURL() else {
            XCTFail("Failed to get documents directory")
            return
        }
        let urlA = documents.appendingPathComponent("example.txt")
        let urlB = documents.appendingPathComponent("nonexistant.txt")
        try files.write(to: urlA, string: "Example", encoding: .utf8)
        XCTAssertEqual(
            files.exists(at: urlA),
            true
        )
        XCTAssertEqual(
            files.exists(at: urlB),
            false
        )
    }

    func testMockFileIOMove() throws {
        let files = MockFileIO()
        guard let documents = files.documentsDirectoryURL() else {
            XCTFail("Failed to get documents directory")
            return
        }
        let srcURL = documents.appendingPathComponent("example.txt")
        let dstURL = documents.appendingPathComponent("example2.txt")
        try files.write(to: srcURL, string: "Example", encoding: .utf8)
        try files.move(at: srcURL, to: dstURL)
        XCTAssertEqual(
            files.read(at: srcURL),
            nil
        )
        XCTAssertEqual(
            files.read(at: dstURL, encoding: .utf8),
            "Example"
        )
    }

    func testMockFileIORemove() throws {
        let files = MockFileIO()
        guard let documents = files.documentsDirectoryURL() else {
            XCTFail("Failed to get documents directory")
            return
        }
        let srcURL = documents.appendingPathComponent("example.txt")
        try files.write(to: srcURL, string: "Example", encoding: .utf8)
        try files.remove(at: srcURL)
        XCTAssertEqual(
            files.read(at: srcURL),
            nil
        )
    }

    func testMockIOHistory() throws {
        let files = MockFileIO()
        guard let documents = files.documentsDirectoryURL() else {
            XCTFail("Failed to get documents directory")
            return
        }
        let srcURL = documents.appendingPathComponent("example.txt")
        let dstURL = documents.appendingPathComponent("example2.txt")
        try files.write(to: srcURL, string: "Example", encoding: .utf8)
        try files.move(at: srcURL, to: dstURL)
        try files.remove(at: dstURL)
        XCTAssertEqual(
            files.history[0],
            MockFileIO.Event.write(url: srcURL)
        )
        XCTAssertEqual(
            files.history[1],
            MockFileIO.Event.move(from: srcURL, to: dstURL)
        )
        XCTAssertEqual(
            files.history[2],
            MockFileIO.Event.remove(url: dstURL)
        )
    }
}
