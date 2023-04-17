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
    
    func testWriteThenReadMemo() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        let memoIn = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try await environment.data.writeMemo(
            address: address,
            memo: memoIn
        )
        
        let memoOut = try await environment.data.readMemo(address: address)
        
        XCTAssertEqual(memoOut.body, memoIn.body)
    }
    
    func testReadMemoBeforeWrite() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        
        let memo = try? await environment.data.readMemo(address: address)
        XCTAssertNil(memo)
    }
    
    func testWriteThenBadSyncThenReadMemo() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        let memoIn = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try await environment.data.writeMemo(
            address: address,
            memo: memoIn
        )
        
        // Supposed to fail
        let synced = try? await environment.noosphere.sync()
        XCTAssertNil(synced)
        
        let memoOut = try await environment.data.readMemo(address: address)
        
        XCTAssertEqual(memoOut.body, memoIn.body)
    }
    
    func testWriteThenBadSyncThenReadDetail() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let address = Slug(formatting: "Test")!.toPublicMemoAddress()
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        try await environment.data.writeMemo(
            address: address,
            memo: memo
        )
        
        // Supposed to fail
        let synced = try? await environment.noosphere.sync()
        XCTAssertNil(synced)
        
        let detail = try await environment.data.readMemoEditorDetail(
            address: address,
            fallback: "Fallback content"
        )
        
        XCTAssertEqual(detail.entry.address, address)
        XCTAssertEqual(detail.entry.contents.body, memo.body)
    }
    
    func testManyWritesThenCloseThenReopen() async throws {
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
            
            let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
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
            
            versionX = try await noosphere.version()
            
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
            
            try await data.writeMemo(address: addressA, memo: memo)
            versionA = try await noosphere.version()
            try await data.writeMemo(address: addressB, memo: memo)
            versionB = try await noosphere.version()
            try await data.writeMemo(address: addressC, memo: memo)
            versionC = try await noosphere.version()
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
        let versionY = try await noosphere.version()
        
        XCTAssertNotEqual(versionY, versionX)
        XCTAssertNotEqual(versionY, versionA)
        XCTAssertNotEqual(versionY, versionB)
        // HEAD is at last version
        XCTAssertEqual(versionY, versionC)
        
        let addressB = Slug(formatting: "b")!.toPublicMemoAddress()
        let memoB = try await data.readMemo(address: addressB)
        XCTAssertEqual(memoB.body, "Test content")
        
        let addressC = Slug(formatting: "c")!.toPublicMemoAddress()
        let memoC = try await data.readMemo(address: addressC)
        XCTAssertEqual(memoC.body, "Test content")
    }
    
    func testFindUniqueAddressFor() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
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
        try await environment.data.writeMemo(address: addressA, memo: memo)
        
        let addressA2 = await environment.data
            .findUniqueAddressFor(title, audience: .local)
        XCTAssertEqual(addressA2?.description, "local::/a-2")
    }
    
    func testReadMemoDetail() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let memo = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [],
            body: "Test content"
        )
        
        let addressA = MemoAddress.public(Slashlink("/a")!)
        try await environment.data.writeMemo(address: addressA, memo: memo)
        
        let detail = await environment.data.readMemoDetail(address: addressA)
        
        XCTAssertEqual(detail?.entry.address, addressA)
        XCTAssertEqual(detail?.entry.contents.body, memo.body)
    }
    
    func testReadMemoDetailDoesNotExist() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let environment = try await TestUtilities.createDataServiceEnvironment(
            tmp: tmp
        )
        
        let addressA = MemoAddress.public(Slashlink("/a")!)

        let detail = await environment.data.readMemoDetail(address: addressA)
        XCTAssertNil(detail)
    }
}
