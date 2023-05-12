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
    
    func testTransactionRelease() throws {
        let tmp = try createTmp(path: UUID().uuidString)
        let url = tmp.appending(
            path: "sqlite.db",
            directoryHint: .notDirectory
        )
        let database = SQLite3Database(
            path: url.absoluteString
        )
        try database.savepoint("test")
        try database.executescript(sql: "PRAGMA user_version = 2;")
        try database.release("test")
        let version = try database.getUserVersion()
        XCTAssertEqual(version, 2)
    }
    
    func testTransactionRollback() throws {
        let tmp = try createTmp(path: UUID().uuidString)
        let url = tmp.appending(
            path: "sqlite.db",
            directoryHint: .notDirectory
        )
        let database = SQLite3Database(
            path: url.absoluteString
        )
        try database.savepoint("test")
        try database.executescript(sql: "PRAGMA user_version = 2;")
        try database.rollback("test")
        let version = try database.getUserVersion()
        XCTAssertEqual(version, 0)
    }
    
    func testTextOptional() throws {
        let value = SQLite3Database.Value.text(nil)
        XCTAssertEqual(value, SQLite3Database.Value.null)
    }
    
    func testIntegerOptional() throws {
        let value = SQLite3Database.Value.integer(nil)
        XCTAssertEqual(value, SQLite3Database.Value.null)
    }
    
    func testRealOptional() throws {
        let value = SQLite3Database.Value.real(nil)
        XCTAssertEqual(value, SQLite3Database.Value.null)
    }
    
    func testBlobOptional() throws {
        let value = SQLite3Database.Value.blob(nil)
        XCTAssertEqual(value, SQLite3Database.Value.null)
    }
}
