//
//  Tests_DetailStack.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 6/9/2023.
//

import XCTest
import ObservableStore
import Combine
@testable import Subconscious

class Tests_DetailStack: XCTestCase {
    let environment = AppEnvironment()
    var cancellable: AnyCancellable?
    
    func testFindBestLinkAddressNoContext() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let _ = try await data.noosphere.createSphere(ownerKeyName: "quick-test")
        
        try await data.noosphere.write(
            slug: Slug(
                "test"
            )!,
            contentType: "text/subtext",
            additionalHeaders: [],
            body: (
                "hello"
            ).toData(
                encoding: .utf8
            )!
        )
        try await data.noosphere.save()
        
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        
        let address = try await DetailStackModel.findBestAddressForLink(
            link: link,
            context: nil,
            environment: data
        )
       
        XCTAssertEqual(address.slug, slashlink.slug)
        XCTAssertEqual(address.peer, slashlink.peer)
    }
    
    func testFindBestLinkAddressWithContext() async throws {
        let tmp = try TestUtilities.createTmpDir()
        let data = try await TestUtilities.createDataServiceEnvironment(tmp: tmp)
        
        let _ = try await data.noosphere.createSphere(ownerKeyName: "quick-test")
        
        // Follow a user and attempt to navigate to a link based on them
        
        try await data.noosphere.write(
            slug: Slug(
                "test"
            )!,
            contentType: "text/subtext",
            additionalHeaders: [],
            body: (
                "hello"
            ).toData(
                encoding: .utf8
            )!
        )
        try await data.noosphere.save()
        
        let friend = Did.dummyData()
        let friendName = Petname("friend")!
        try await data.addressBook.followUser(did: friend, petname: friendName)
        
        let slashlink = Slashlink(slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        
        let peer = Peer.petname(friendName)
        let address = try await DetailStackModel.findBestAddressForLink(
            link: link,
            context: Peer.petname(friendName),
            environment: data
        )
       
        XCTAssertEqual(address.slug, slashlink.slug)
        XCTAssertEqual(address.peer, peer)
    }
    
    func testFindAndPushLinkDetail() throws {
        throw XCTSkip(
          """
          This test is brittle in CI.
          However, it's useful to check concurrent behaviour locally.
          """
        )
        
        let model = DetailStackModel()
        
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let address = Slashlink(petname: Petname("origin")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        let did = Did.dummyData()
        let context = Peer.did(did)
        
        let update = DetailStackModel.update(
            state: model,
            action: .findAndPushLinkDetail(context: context, link: link),
            environment: environment
        )
        let expectation = XCTestExpectation(
            description: "findAndPushDetail is sent"
        )
        self.cancellable = update.fx.sink(
            receiveCompletion: { completion in
                expectation.fulfill()
            },
            receiveValue: { action in
                switch action {
                case let .findAndPushDetail(address: newAddress):
                    XCTAssertEqual(Slashlink("@bob.alice.origin/hello"), newAddress)
                    default:
                        XCTFail("Incorrect action")
                    }
                }
            )
        wait(for: [expectation], timeout: 2.0)
    }


    func testViewerSlashlinkConstruction() throws {
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let address = Slashlink(petname: Petname("origin")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        let did = Did.dummyData()
        
        let action = MemoViewerDetailNotification.requestFindLinkDetail(
            context: Peer.did(did),
            link: link
        )
        
        let newAction = DetailStackAction.tag(action)
        switch newAction {
        case let .findAndPushLinkDetail(context, newLink):
            XCTAssertEqual(did, context?.did)
            XCTAssertEqual(link, newLink)
        default:
            XCTFail("Incorrect action")
        }
    }

    func testEditorSlashlinkConstruction() throws {
        let slashlink = Slashlink(petname: Petname("bob.alice")!, slug: Slug("hello")!)
        let link = SubSlashlinkLink(slashlink: slashlink)
        let did = Did.dummyData()
        
        let action = MemoEditorDetailNotification.requestFindLinkDetail(
            context: Peer.did(did),
            link: link
        )
        
        let newAction = DetailStackAction.tag(action)
        
        switch newAction {
        case let .findAndPushLinkDetail(context, newLink):
            XCTAssertEqual(did, context?.did)
            XCTAssertEqual(newLink, link)
        default:
            XCTFail("Incorrect action")
        }
    }
    
    func testSucceedDeleteMemo() throws {
        let address = Slashlink("/test")!
        
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: address, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-2")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-3")!, fallback: ""),
        ])

        let update = DetailStackModel.update(
            state: state,
            action: .succeedDeleteMemo(address),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            2,
            "Removes deleted detail"
        )
        
        XCTAssertEqual(update.state.details[0].address, Slashlink("/test-2")!)
        XCTAssertEqual(update.state.details[1].address, Slashlink("/test-3")!)
    }
    
    func testSucceedUpdateAudience() throws {
        let address = Slashlink("/test")!
        let updatedAddress = Slashlink(peer: .did(Did.local), slug: Slug("test")!)
        
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: address, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-2")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-3")!, fallback: ""),
        ])

        let update = DetailStackModel.update(
            state: state,
            action: .succeedUpdateAudience(
                MoveReceipt(
                    from: address,
                    to: updatedAddress
                )
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            3,
            "Preserves details"
        )
        
        // audience is now local
        XCTAssertEqual(update.state.details[0].address, updatedAddress)
        XCTAssertEqual(update.state.details[1].address, Slashlink("/test-2")!)
        XCTAssertEqual(update.state.details[2].address, Slashlink("/test-3")!)
    }
    
    func testSucceedMoveEntry() throws {
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: Slashlink("/test")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-2")!, fallback: ""),
            MemoDetailDescription.from(address: Slashlink("/test-3")!, fallback: ""),
        ])

        let address = Slashlink("/test-3")!
        let updatedAddress = Slashlink("/foo")!

        let update = DetailStackModel.update(
            state: state,
            action: .succeedMoveEntry(from: address, to: updatedAddress),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            3,
            "Preserves details"
        )
        
        XCTAssertEqual(update.state.details[0].address, Slashlink("/test")!)
        XCTAssertEqual(update.state.details[1].address, Slashlink("/test-2")!)
        // test-3 has become foo
        XCTAssertEqual(update.state.details[2].address, updatedAddress)
    }
    
    func testSucceedMergeEntry() throws {
        let address = Slashlink("/test-3")!
        let parent = Slashlink("/test-2")!
        
        let state = DetailStackModel(details: [
            MemoDetailDescription.from(address: Slashlink("/test")!, fallback: ""),
            MemoDetailDescription.from(address: parent, fallback: ""),
            MemoDetailDescription.from(address: address, fallback: ""),
        ])

        let update = DetailStackModel.update(
            state: state,
            action: .succeedMergeEntry(
                parent: parent,
                child: address
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.details.count,
            3,
            "Preserves details"
        )
        
        XCTAssertEqual(update.state.details[0].address, Slashlink("/test")!)
        // test-3 has been turned into test-2
        XCTAssertEqual(update.state.details[1].address, parent)
        XCTAssertEqual(update.state.details[2].address, parent)
    }
}
