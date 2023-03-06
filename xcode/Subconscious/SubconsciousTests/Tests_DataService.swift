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
    /// Create a unique temp dir and return URL
    func createTmpDir() throws -> URL {
        let path = UUID().uuidString
        let url = FileManager.default.temporaryDirectory.appending(
            path: path,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }
    
    /// Set up and return a data service instance
    func createDataService(
        tmp: URL
    ) throws -> DataService {
        let globalStorageURL = tmp.appending(path: "noosphere")
        let sphereStorageURL = tmp.appending(path: "sphere")
        
        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL,
            gatewayURL: URL(string: "http://unavailable-gateway.fakewebsite")
        )
        
        let receipt = try noosphere.createSphere(ownerKeyName: "bob")
        noosphere.resetSphere(receipt.identity)
        
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
        
        return DataService(
            noosphere: noosphere,
            database: database,
            local: local
        )
    }
    
    /// A place to put cancellables from publishers
    var cancellables: Set<AnyCancellable> = Set()
    
    var data: DataService?
    
    func testWriteThenReadMemo() throws {
        let tmp = try createTmpDir()
        let data = try createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
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
        let tmp = try createTmpDir()
        let data = try createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        
        XCTAssertThrowsError(try data.readMemo(address: address))
    }
    
    func testWriteThenBadSyncThenReadMemo() throws {
        let tmp = try createTmpDir()
        let data = try createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
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
        let tmp = try createTmpDir()
        let data = try createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
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
    
    func testManyWritesThenCloseThenReopen() throws {
        let tmp = try createTmpDir()
        var data = try createDataService(tmp: tmp)
        
        let versionX = try data.noosphere.version()
        print("!!! X", versionX)
        
        let addressA = Slug(formatting: "a")!.toPublicMemoAddress()
        let addressB = Slug(formatting: "b")!.toPublicMemoAddress()
        let addressC = Slug(formatting: "c")!.toPublicMemoAddress()
        let addressD = Slug(formatting: "d")!.toPublicMemoAddress()
        
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: "Test",
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try data.writeMemo(address: addressA, memo: memo)
        let versionA = try data.noosphere.version()
        print("!!! A", versionA)
        try data.writeMemo(address: addressB, memo: memo)
        let versionB = try data.noosphere.version()
        print("!!! B", versionB)
        try data.writeMemo(address: addressC, memo: memo)
        let versionC = try data.noosphere.version()
        print("!!! C", versionC)
        try data.writeMemo(address: addressD, memo: memo)
        let versionD = try data.noosphere.version()
        print("!!! D", versionD)
        
        // Create a new instance
        data = try createDataService(tmp: tmp)
        
        let versionY = try data.noosphere.version()
        print("!!! Y", versionY)
        
        XCTAssertNotEqual(versionY, versionX)
        XCTAssertNotEqual(versionY, versionA)
        XCTAssertNotEqual(versionY, versionB)
        XCTAssertNotEqual(versionY, versionC)
        XCTAssertEqual(versionY, versionD)
        
        let memoB = try data.readMemo(address: addressB)
        XCTAssertEqual(memoB.body, "Test content")
        
        let memoD = try data.readMemo(address: addressD)
        XCTAssertEqual(memoD.body, "Test content")
    }
    
    func findUniqueLocalAddressFor() throws {
        let tmp = try createTmpDir()
        let data = try createDataService(tmp: tmp)
        
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: "Test",
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        let title = "A"
        let addressA = Slug(formatting: title)!.toPublicMemoAddress()
        try data.writeMemo(address: addressA, memo: memo)

        let addressA2 = data.findUniqueLocalAddressFor(title)
        XCTAssertEqual(addressA2?.description, "local::/a-2")
    }
}
