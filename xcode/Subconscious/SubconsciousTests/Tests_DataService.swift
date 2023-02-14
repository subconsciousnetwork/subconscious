//
//  Tests_DataService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/13/23.
//

import XCTest
import Combine
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

    func testThing() throws {
        let data = self.data!

        let failSync = expectation(description: "Fails to sync (intentional)")
        let succeedSync = expectation(description: "Syncs (should not happen)")
        succeedSync.isInverted = true

        data.syncSphereWithGateway()
            .sink(
                receiveCompletion: { completion in
                    failSync.fulfill()
                },
                receiveValue: { value in
                    succeedSync.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [failSync, succeedSync], timeout: 0.2)
    }
}
