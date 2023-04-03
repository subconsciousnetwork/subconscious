//
//  TestUtilities.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 3/4/2023.
//

import XCTest
import Combine
import ObservableStore
@testable import Subconscious

struct TestUtilities {
    /// Create a unique temp dir and return URL
    static func createTmpDir() throws -> URL {
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
    static func createDataService(
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
        let addressBook = AddressBookService(
            noosphere: noosphere,
            database: database
        )
        
        return DataService(
            noosphere: noosphere,
            database: database,
            local: local,
            addressBook: addressBook
        )
    }
}
