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
    /// A place to put cancellables from publishers
    var cancellables: Set<AnyCancellable> = Set()
    
    var data: DataService?
    
    func testWriteThenReadMemo() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        let memoIn = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try data.writeMemo(
            address: address,
            memo: memoIn
        )
        
        let memoOut = try data.readMemo(address: address)
        
        XCTAssertEqual(memoOut.body, memoIn.body)
    }
    
    func testReadMemoBeforeWrite() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        
        XCTAssertThrowsError(try data.readMemo(address: address))
    }
    
    func testWriteThenBadSyncThenReadMemo() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        let memoIn = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
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
        
        XCTAssertEqual(memoOut.body, memoIn.body)
    }
    
    func testWriteThenBadSyncThenReadDetail() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
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
        
        let detail = try data.readMemoEditorDetail(
            address: address,
            fallback: "Fallback content"
        )
        
        XCTAssertEqual(detail.entry.address, address)
        XCTAssertEqual(detail.entry.contents.body, memo.body)
    }
    
    func testManyWritesThenCloseThenReopen() throws {
        let tmp = try TestUtilities.createTmpDir()
        
        let globalStorageURL = tmp.appending(path: "noosphere")
        let sphereStorageURL = tmp.appending(path: "sphere")
        
        let sphereIdentity: String
        // Create sphere and initialize sphereIdentity.
        // We run this in a block to ensure destructor is called at end
        // of block scope. Swift does not guarantee destructors will be
        // called until end of scope.
        do {
            let noosphere = NoosphereService(
                globalStorageURL: globalStorageURL,
                sphereStorageURL: sphereStorageURL,
                gatewayURL: URL(string: "http://unavailable-gateway.fakewebsite")
            )
            
            let receipt = try noosphere.createSphere(ownerKeyName: "bob")
            sphereIdentity = receipt.identity
        }
        
        // Create and set up other sub-services
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
        
        
        let versionX: String
        let versionA: String
        let versionB: String
        let versionC: String
        
        // Run data service in block to ensure destructor is called at end
        // of block scope.
        do {
            let noosphere = NoosphereService(
                globalStorageURL: globalStorageURL,
                sphereStorageURL: sphereStorageURL,
                gatewayURL: URL(string: "http://unavailable-gateway.fakewebsite"),
                sphereIdentity: sphereIdentity
            )
            let addressBook = AddressBookService(
                noosphere: noosphere,
                database: database
            )

            let data = DataService(
                noosphere: noosphere,
                database: database,
                local: local,
                addressBook: addressBook
            )
            
            versionX = try data.noosphere.version()
            
            let addressA = Slug(formatting: "a")!.toPublicMemoAddress()
            let addressB = Slug(formatting: "b")!.toPublicMemoAddress()
            let addressC = Slug(formatting: "c")!.toPublicMemoAddress()
            
            let memo = Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Test content"
            )
            
            try data.writeMemo(address: addressA, memo: memo)
            versionA = try data.noosphere.version()
            try data.writeMemo(address: addressB, memo: memo)
            versionB = try data.noosphere.version()
            try data.writeMemo(address: addressC, memo: memo)
            versionC = try data.noosphere.version()
        }
        
        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL,
            gatewayURL: URL(string: "http://unavailable-gateway.fakewebsite"),
            sphereIdentity: sphereIdentity
        )
        let addressBook = AddressBookService(
            noosphere: noosphere,
            database: database
        )

        let data = DataService(
            noosphere: noosphere,
            database: database,
            local: local,
            addressBook: addressBook
        )
        let versionY = try data.noosphere.version()
        
        XCTAssertNotEqual(versionY, versionX)
        XCTAssertNotEqual(versionY, versionA)
        XCTAssertNotEqual(versionY, versionB)
        // HEAD is at last version
        XCTAssertEqual(versionY, versionC)
        
        let addressB = Slug(formatting: "b")!.toPublicMemoAddress()
        let memoB = try data.readMemo(address: addressB)
        XCTAssertEqual(memoB.body, "Test content")
        
        let addressC = Slug(formatting: "c")!.toPublicMemoAddress()
        let memoC = try data.readMemo(address: addressC)
        XCTAssertEqual(memoC.body, "Test content")
    }
    
    func testFindUniqueAddressFor() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        let title = "A"
        let addressA = Slug(formatting: title)!.toPublicMemoAddress()
        try data.writeMemo(address: addressA, memo: memo)
        
        let addressA2 = data.findUniqueAddressFor(title, audience: .local)
        XCTAssertEqual(addressA2?.description, "local::/a-2")
    }
    
    func testReadMemoDetail() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        let addressA = MemoAddress.public(Slashlink("/a")!)
        try data.writeMemo(address: addressA, memo: memo)
        
        let detail = data.readMemoDetail(address: addressA)
        
        XCTAssertEqual(detail?.entry.address, addressA)
        XCTAssertEqual(detail?.entry.contents.body, memo.body)
    }
    
    func testReadMemoDetailDoesNotExist() throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try TestUtilities.createDataService(tmp: tmp)
        
        let addressA = MemoAddress.public(Slashlink("/a")!)

        XCTAssertNil(data.readMemoDetail(address: addressA))
    }
}
