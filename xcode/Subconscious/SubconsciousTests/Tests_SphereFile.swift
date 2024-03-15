//
//  Tests_SphereFile.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/20/23.
//

import XCTest
@testable import Subconscious

final class Tests_SphereFile: XCTestCase {
    func createNoosphere() async throws -> Noosphere {
        let tmp = try TestUtilities.createTmpDir()
        let globalStorageURL = tmp.appending(path: "noosphere")
        let sphereStorageURL = tmp.appending(path: "sphere")
        let gatewayURL = "https://fake.website.example.com"
        let noosphere = try await Noosphere(
            globalStoragePath: globalStorageURL.path(percentEncoded: false),
            sphereStoragePath: sphereStorageURL.path(percentEncoded: false),
            gatewayURL: gatewayURL
        )
        return noosphere
    }
    
    func testVersion() async throws {
        let noosphere = try await createNoosphere()
        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        let sphere = try await Sphere(
            noosphere: noosphere,
            identity: receipt.identity
        )
        let body = "Foo".toData()!
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.save()
        let file = try await sphere.readFile(slashlink: Slashlink("/foo")!)
        _ = try await file.version()
    }

    func testReadHeaderValueFirst() async throws {
        let noosphere = try await createNoosphere()
        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        let sphere = try await Sphere(
            noosphere: noosphere,
            identity: receipt.identity
        )
        let body = "Foo bar".toData()!
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.save()
        let file = try await sphere.readFile(slashlink: Slashlink("/foo")!)
        let value = try await file.readHeaderValueFirst(name: "Content-Type")
        XCTAssertEqual(value, "text/subtext")
        let length = try await file.readHeaderValueFirst(name: "Content-Length")
        XCTAssertEqual(length, "\(body.count)")
    }
    
    func testReadHeaderNames() async throws {
        let noosphere = try await createNoosphere()
        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        let sphere = try await Sphere(
            noosphere: noosphere,
            identity: receipt.identity
        )
        let body = "Foo".toData()!
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.save()
        let file = try await sphere.readFile(slashlink: Slashlink("/foo")!)
        let names = try await file.readHeaderNames()
        XCTAssertTrue(names.contains("Content-Type"))
        XCTAssertTrue(names.contains("Content-Length"))
        XCTAssertEqual(names.count, 2)
    }

    func testConsume() async throws {
        let noosphere = try await createNoosphere()
        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        let sphere = try await Sphere(
            noosphere: noosphere,
            identity: receipt.identity
        )
        let body = "Foo".toData()!
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.save()
        let file = try await sphere.readFile(slashlink: Slashlink("/foo")!)
        let bodyData = try await file.consumeContents()
        let body2 = bodyData.toString()
        XCTAssertEqual(body2, "Foo")
    }
    
    func testUseAfterConsumeThrows() async throws {
        let noosphere = try await createNoosphere()
        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        let sphere = try await Sphere(
            noosphere: noosphere,
            identity: receipt.identity
        )
        let body = "Foo".toData()!
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.save()
        let file = try await sphere.readFile(slashlink: Slashlink("/foo")!)
        _ = try await file.consumeContents()
        do {
            _ = try await file.consumeContents()
            XCTFail("Succeeded, but should have failed")
        } catch {
            switch error {
            case SphereFileError.consumed:
                break
            default:
                XCTFail("Wrong error. Expected: SphereFileError.consumed. Got: \(error)")
            }
        }
    }
    
    func testUseAfterConsumeThrows2() async throws {
        let noosphere = try await createNoosphere()
        let receipt = try await noosphere.createSphere(ownerKeyName: "bob")
        let sphere = try await Sphere(
            noosphere: noosphere,
            identity: receipt.identity
        )
        let body = "Foo".toData()!
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.save()
        let file = try await sphere.readFile(slashlink: Slashlink("/foo")!)
        _ = try await file.consumeContents()
        do {
            _ = try await file.readHeaderValueFirst(name: "Content-Type")
            XCTFail("Succeeded, but should have failed")
        } catch {
            switch error {
            case SphereFileError.consumed:
                break
            default:
                XCTFail("Wrong error. Expected: SphereFileError.consumed. Got: \(error)")
            }
        }
    }
}
