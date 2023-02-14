//
//  Tests_DataService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/13/23.
//

import XCTest
import Combine
import ObservableStore
@testable import Subconscious

final class Tests_DataService: XCTestCase {
    /// Get URL to temp dir for this test instance
    func createTmp(path: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: path, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }
    
    /// A place to put cancellables from publishers
    var cancellables: Set<AnyCancellable> = Set()
    
    var data: DataService?
    
    override func setUpWithError() throws {
        let id = UUID()
        let tmp = try createTmp(path: id.uuidString)
        let globalStorageURL = tmp.appending(path: "noosphere")
        let sphereStorageURL = tmp.appending(path: "sphere")
        
        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL,
            gatewayURL: URL(string: "http://unavailable-gateway.fakewebsite")
        )
        
        let receipt = try noosphere.createSphere(ownerKeyName: "bob")
        noosphere.updateDefaultSphere(receipt.identity)
        
        let databaseURL = tmp.appending(
            path: "database.sqlite",
            directoryHint: .notDirectory
        )
        let db = SQLite3Database(
            path: databaseURL.path(percentEncoded: false),
            mode: .readwrite
        )
        
        let database = DatabaseService(
            database: db,
            migrations: Config.migrations
        )
        _ = try database.migrate()
        
        let files = FileStore(
            documentURL: tmp.appending(path: "docs")
        )
        
        let local = HeaderSubtextMemoStore(store: files)
        
        let data = DataService(
            noosphere: noosphere,
            database: database,
            local: local
        )
        
        self.data = data
    }
    
    func testWriteThenReadMemo() throws {
        let data = self.data!
        
        let address = MemoAddress(formatting: "Test", audience: .public)!
        let memoIn = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: "Test",
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try data.writeMemo(
            address: address,
            memo: memoIn
        )
        
        let memoOut = try data.readMemo(address: address)
        
        XCTAssertEqual(memoOut.title, memoIn.title)
        XCTAssertEqual(memoOut.body, memoIn.body)
    }
    
    func testReadMemoBeforeWrite() throws {
        let data = self.data!
        
        let address = MemoAddress(formatting: "Test", audience: .public)!
        
        XCTAssertThrowsError(try data.readMemo(address: address))
    }

    func testWriteThenBadSyncThenReadMemo() throws {
        let data = self.data!
        
        let address = MemoAddress(formatting: "Test", audience: .public)!
        let memoIn = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: "Test",
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try data.writeMemo(
            address: address,
            memo: memoIn
        )
        
        // Supposed to fail
        XCTAssertThrowsError(try data.noosphere.sync())
        
        let memoOut = try data.readMemo(address: address)
        
        XCTAssertEqual(memoOut.title, memoIn.title)
        XCTAssertEqual(memoOut.body, memoIn.body)
    }
    
    func testWriteThenBadSyncThenReadDetail() throws {
        let data = self.data!
        
        let address = MemoAddress(formatting: "Test", audience: .public)!
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: "Test",
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try data.writeMemo(
            address: address,
            memo: memo
        )
        
        // Supposed to fail
        XCTAssertThrowsError(try data.noosphere.sync())
        
        let detail = try data.readDetail(
            address: address,
            title: "Test fallback",
            fallback: "Fallback content"
        )
        
        XCTAssertEqual(detail.entry.address, address)
        XCTAssertEqual(detail.entry.contents.body, memo.body)
        XCTAssertEqual(detail.entry.contents.title, memo.title)
    }
}
