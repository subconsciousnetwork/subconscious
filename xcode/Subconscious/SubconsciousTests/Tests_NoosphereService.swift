//
//  Tests_NoosphereService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/16/23.
//

import XCTest
@testable import Subconscious

final class Tests_NoosphereService: XCTestCase {
    /// Create a unique temp dir and return URL
    static func createTmpDir(_ path: String) throws -> URL {
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
    
    func testSphereTraversal() async throws {
        throw XCTSkip("Sphere Traversal relies on running a gateway, this test will not pass currently.")
        
        let tmp = try TestUtilities.createTmpDir()
        let globalStorageURL = tmp.appending(path: "noosphere")
        let sphereStorageURL = tmp.appending(path: "sphere")
        
        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL,
            gatewayURL: URL(string: "http://unavailable-gateway.fakewebsite")
        )
        
        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        await noosphere.resetSphere(receipt.identity)

        let bobReceipt = try await noosphere.createSphere(ownerKeyName: "bob")
        let aliceReceipt = try await noosphere.createSphere(ownerKeyName: "alice")
        
        let bob = Petname("bob")!
        let bobDid = Did(bobReceipt.identity)!
        let alice = Petname("alice")!
        let aliceDid = Did(aliceReceipt.identity)!

        // Put bob in alice's address book
        await noosphere.resetSphere(aliceReceipt.identity)
        try await noosphere.setPetname(did: bobDid, petname: bob)
        try await noosphere.save()
        
        let bobDid2 = try await noosphere.getPetname(petname: bob)
        XCTAssertEqual(bobDid2, bobDid)
        
        // Put alice in bob's address book & set bob as default sphere
        await noosphere.resetSphere(bobReceipt.identity)
        try await noosphere.setPetname(did: aliceDid, petname: alice)
        try await noosphere.save()
        
        let aliceDid2 = try await noosphere.getPetname(petname: alice)
        XCTAssertEqual(aliceDid2, aliceDid)
        
        _ = try await noosphere.sync()
        // This should loop back around to bob
        let destinationSphere = try await noosphere
            .traverse(petname: alice)
            .traverse(petname: bob)

        // Clear out Noosphere and Sphere instance
        await noosphere.reset()
        
        let sphereIdentity = try await destinationSphere.identity()
        XCTAssertEqual(sphereIdentity, bobDid)
    }
    
    func testNoosphereReset() async throws {
        let base = UUID()
        
        let globalStorageURL = try Self.createTmpDir("\(base)/noosphere")
        let sphereStorageURL = try Self.createTmpDir("\(base)/sphere")

        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL
        )

        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        await noosphere.resetSphere(receipt.identity)

        let versionA = try await noosphere.version()
        
        let body = try "Test content".toData().unwrap()
        try await noosphere.write(
            slug: Slug("a")!,
            contentType: "text/subtext",
            additionalHeaders: [],
            body: body
        )
        let versionB = try await noosphere.save()
        XCTAssertNotEqual(versionA, versionB)

        try await noosphere.write(
            slug: Slug("b")!,
            contentType: "text/subtext",
            additionalHeaders: [],
            body: body
        )
        try await noosphere.write(
            slug: Slug("c")!,
            contentType: "text/subtext",
            additionalHeaders: [],
            body: body
        )
        let versionC = try await noosphere.save()
        XCTAssertNotEqual(versionB, versionC)

        // Clear out Noosphere and Sphere instance
        await noosphere.reset()

        let versionZ = try await noosphere.version()
        XCTAssertEqual(versionC, versionZ)
    }
    
    func testPathologicalDisposalOfNoosphere() async throws {
        let base = UUID()
        
        let globalStorageURL = try Self.createTmpDir("\(base)/noosphere")
        let sphereStorageURL = try Self.createTmpDir("\(base)/sphere")
        
        func innerA() async throws -> SphereReceipt {
            let noosphere = NoosphereService(
                globalStorageURL: globalStorageURL,
                sphereStorageURL: sphereStorageURL
            )
            
            let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
            await noosphere.resetSphere(receipt.identity)
            
            let versionA = try await noosphere.version()
            
            return receipt
        }
        
        func innerB(receipt: SphereReceipt) async throws {
            let noosphere = NoosphereService(
                globalStorageURL: globalStorageURL,
                sphereStorageURL: sphereStorageURL
            )
            
            await noosphere.resetSphere(receipt.identity)
            
            let taskA = Task {
                for _ in 0..<1000 {
                    let body = try "Test content".toData().unwrap()
                    let slug = Slug.dummyData()
                    try await noosphere.write(
                        slug: slug,
                        contentType: "text/subtext",
                        additionalHeaders: [],
                        body: body
                    )
                    
                    let body2 = try "Test content 2".toData().unwrap()
                    try await noosphere.write(
                        slug: slug,
                        contentType: "text/subtext",
                        additionalHeaders: [],
                        body: body2
                    )
                    
                    let _ = try await noosphere.save()
                    
                    try await noosphere.remove(slug: slug)
                    
                    let _ = try await noosphere.save()
                }
            }
            
            let taskB = Task {
                for _ in 0..<1000 {
                    let body = try "Test content".toData().unwrap()
                    let slug = Slug.dummyData()
                    try await noosphere.write(
                        slug: slug,
                        contentType: "text/subtext",
                        additionalHeaders: [],
                        body: body
                    )
                    
                    let _ = try await noosphere.save()
                    
                    try await noosphere.remove(slug: slug)
                    
                    let _ = try await noosphere.save()
                    
                    Task {
                        let _ = try await noosphere.sync()
                    }
                }
            }
            
            taskA.cancel()
            taskB.cancel()
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        let receipt = try await innerA()
        try await innerB(receipt: receipt)
        try await innerB(receipt: receipt)
        
        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL
        )
        
        await noosphere.resetSphere(receipt.identity)
        let slugs = try await noosphere.list()
        XCTAssert(slugs.count <= 2)
    }
}
