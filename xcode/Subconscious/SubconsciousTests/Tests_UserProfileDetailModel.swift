//
//  Tests_UserProfileDetailModel.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 14/11/2023.
//

import XCTest
@testable import Subconscious

class Tests_UserProfileDetailModel: XCTestCase {
    func testProfileActionMapping() throws {
        let did = Did.dummyData()
        let petname = Petname.dummyData()
        
        XCTAssertEqual(
            UserProfileDetailAction.toAppAction(
                .attemptFollow(
                    identity: did,
                    petname: petname
                )
            ),
            .followPeer(
                identity: did,
                petname: petname
            )
        )
        
        XCTAssertEqual(
            UserProfileDetailAction.toAppAction(
                .attemptUnfollow(
                    identity: did,
                    petname: petname
                )
            ),
            .unfollowPeer(
                identity: did,
                petname: petname
            )
        )
        
        let newName = Petname.dummyData()
        
        XCTAssertEqual(
            UserProfileDetailAction.toAppAction(
                .attemptRename(
                    from: petname,
                    to: newName
                )
            ),
            .renamePeer(
                from: petname,
                to: newName
            )
        )
    }
    
    func testProfileNotificationReaction() throws {
        let did = Did.dummyData()
        let petname = Petname.dummyData()
        
        XCTAssertEqual(
            UserProfileDetailAction.from(
                .completeIndexPeers(results: [])
            ),
            .completeIndexPeers([])
        )
        
        XCTAssertEqual(
            UserProfileDetailAction.from(
                .succeedFollowPeer(did, petname)
            ),
            .succeedFollow(petname)
        )
        
        XCTAssertEqual(
            UserProfileDetailAction.from(
                .succeedUnfollowPeer(
                    identity: did,
                    petname: petname
                )
            ),
            .succeedUnfollow(
                identity: did,
                petname: petname
            )
        )
        
        let newName = Petname.dummyData()
        
        XCTAssertEqual(
            UserProfileDetailAction.from(
                .succeedRenamePeer(
                    identity: did,
                    from: petname,
                    to: newName
                )
            ),
            .succeedRename(
                identity: did,
                from: petname,
                to: newName
            )
        )
    }
    
    func testProfileRefresh() throws {
        let did = Did.dummyData()
        let petname = Petname.dummyData()
        let since = String.dummyDataMedium()
        
        XCTAssertEqual(
            UserProfileDetailAction.from(
                .succeedIndexOurSphere(OurSphereRecord(identity: did, since: since))
            ),
            .refresh(forceSync: false)
        )
        
        XCTAssertEqual(
            UserProfileDetailAction.from(
                .succeedRecoverOurSphere
            ),
            .refresh(forceSync: false)
        )
    }
}
