//
//  Tests_AppModelUpdate.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/2/22.
//

import XCTest
@testable import Subconscious

class Tests_AppModelUpdate: XCTestCase {
    let environment = AppEnvironment()

    func testUpdateDetail() throws {
        let state = AppModel()
        let slug = try Slug("example").unwrap()
        let detail = EntryDetail(
            slug: slug,
            entry: SaveEnvelope(
                state: .saved,
                value: SubtextFile(
                    slug: slug,
                    content: "Example text"
                )
            )
        )
        let update = AppModel.update(
            state: state,
            action: .updateDetail(
                detail: detail,
                autofocus: true
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.editorText,
            "Example text",
            "Sets editor text"
        )
    }

    func testUpdateDetailFocus() throws {
        let state = AppModel()
        let slug = try Slug("example").unwrap()
        let detail = EntryDetail(
            slug: slug,
            entry: SaveEnvelope(
                state: .saved,
                value: SubtextFile(
                    slug: slug,
                    content: "Example text"
                )
            )
        )
        let update = AppModel.update(
            state: state,
            action: .updateDetail(
                detail: detail,
                autofocus: true
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.focus,
            .editor,
            "Autofocus sets editor focus"
        )
    }

    func testUpdateDetailBlur() throws {
        let state = AppModel()
        let slug = try Slug("example").unwrap()
        let detail = EntryDetail(
            slug: slug,
            entry: SaveEnvelope(
                state: .saved,
                value: SubtextFile(
                    slug: slug,
                    content: "Example text"
                )
            )
        )
        let update = AppModel.update(
            state: state,
            action: .updateDetail(
                detail: detail,
                autofocus: false
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.focus,
            nil,
            "Autofocus sets editor focus"
        )
    }

    func testEntryCount() throws {
        let state = AppModel()
        let update = AppModel.update(
            state: state,
            action: .setEntryCount(10),
            environment: environment
        )
        XCTAssertEqual(
            update.state.entryCount,
            10,
            "Entry count correctly set"
        )
    }

    func testDeleteEntry() throws {
        let slugA = Slug("a")!
        let slugB = Slug("b")!
        let slugC = Slug("c")!
        let state = AppModel(
            recent: [
                EntryStub(
                    slug: slugA,
                    title: "A",
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                ),
                EntryStub(
                    slug: slugB,
                    title: "b",
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                ),
                EntryStub(
                    slug: slugC,
                    title: "C",
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                )
            ]
        )
        let update = AppModel.update(
            state: state,
            action: .deleteEntry(slugB),
            environment: environment
        )
        XCTAssertEqual(
            update.state.recent!.count,
            2,
            "Entry count correctly set"
        )
        XCTAssertEqual(
            update.state.recent![0].id,
            slugA,
            "Slug A is still first"
        )
        XCTAssertEqual(
            update.state.recent![1].id,
            slugC,
            "Slug C moved up because slug B was removed"
        )
    }

    func testShowRenameSheet() throws {
        let state = AppModel()
        let slug = Slug("floop-the-pig")!
        let update = AppModel.update(
            state: state,
            action: .showRenameSheet(slug),
            environment: environment
        )

        XCTAssertEqual(
            update.state.isRenameSheetShowing,
            true,
            "Rename sheet is shown"
        )
        XCTAssertEqual(
            update.state.slugToRename,
            slug,
            "slugToRename was set"
        )
    }

    func testHideRenameSheet() throws {
        let state = AppModel()
        let update = AppModel.update(
            state: state,
            action: .hideRenameSheet,
            environment: environment
        )

        XCTAssertEqual(
            update.state.isRenameSheetShowing,
            false,
            "Rename sheet is hidden"
        )
        XCTAssertEqual(
            update.state.slugToRename,
            nil,
            "slugToRename was set"
        )
    }
    
    func testRenameSlugField() throws {
        let state = AppModel()
        let update = AppModel.update(
            state: state,
            action: .setRenameSlugField("I Floop the Pig"),
            environment: environment
        )

        XCTAssertEqual(
            update.state.renameSlugField,
            "i-floop-the-pig",
            "The Pig has been flooped."
        )
    }
}
