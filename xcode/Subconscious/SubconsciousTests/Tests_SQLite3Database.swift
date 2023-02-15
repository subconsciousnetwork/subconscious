//
//  Tests_SQLite3Database.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/15/23.
//

import XCTest
@testable import Subconscious

final class Tests_SQLite3Database: XCTestCase {
    /// Get URL to temp dir for this test instance
    func createTmp(path: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: path,directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    func testDeleteDatabase() throws {
        let tmp = try createTmp(path: UUID().uuidString)
        let url = tmp
            .appending(path: "sqlite.db", directoryHint: .notDirectory)
        let database = SQLite3Database(
            path: url.absoluteString
        )
        try database.executescript(sql: "PRAGMA user_version = 2;")
        XCTAssert(FileManager.default.fileExists(atPath: url.path()))

        try database.delete()
        XCTAssert(!FileManager.default.fileExists(atPath: url.path()))
    }
}
