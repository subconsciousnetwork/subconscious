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
            saveState: .saved,
            entry: SubtextFile(
                slug: slug,
                content: "Example text"
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
            update.state.editor.isLoading,
            false,
            "isDetailLoading set to false"
        )
        XCTAssertEqual(
            update.state.editor.entryInfo?.slug,
            detail.slug,
            "Sets the slug"
        )
        XCTAssertEqual(
            update.state.editor.text,
            "Example text",
            "Sets editor text"
        )
    }

    func testUpdateDetailFocus() throws {
        let state = AppModel()
        let slug = try Slug("example").unwrap()
        let detail = EntryDetail(
            saveState: .saved,
            entry: SubtextFile(
                slug: slug,
                content: "Example text"
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
            saveState: .saved,
            entry: SubtextFile(
                slug: slug,
                content: "Example text"
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

    func testSetEditorFocus() throws {
        let state = AppModel(
            focus: .editor,
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("great-expectations")!
                ),
                saveState: .modified,
                isLoading: false,
                text: "Mr. Pumblechook’s premises in the High Street of the market town, were of a peppercorny and farinaceous character."
            )
        )
        let update = AppModel.update(
            state: state,
            action: .setEditorFocus(nil),
            environment: environment
        )
        XCTAssertEqual(
            update.state.focus,
            nil,
            "Focus was set"
        )
        XCTAssertEqual(
            update.state.editor.saveState,
            .saving,
            "Editor was marked saving"
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
        let a = EntryLink(title: "A")!
        let b = EntryLink(title: "B")!
        let c = EntryLink(title: "C")!
        let state = AppModel(
            recent: [
                EntryStub(
                    link: a,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                ),
                EntryStub(
                    link: b,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                ),
                EntryStub(
                    link: c,
                    excerpt: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum orci quis lorem semper porta. Integer sem eros, ultricies et risus id, congue tristique libero.",
                    modified: Date.now
                )
            ]
        )
        let update = AppModel.update(
            state: state,
            action: .deleteEntry(b.slug),
            environment: environment
        )
        XCTAssertEqual(
            update.state.recent!.count,
            2,
            "Entry count correctly set"
        )
        XCTAssertEqual(
            update.state.recent![0].id,
            a.id,
            "Slug A is still first"
        )
        XCTAssertEqual(
            update.state.recent![1].id,
            c.id,
            "Slug C moved up because slug B was removed"
        )
    }

    func testShowRenameSheet() throws {
        let state = AppModel()
        let link = EntryLink(title: "Floop the Pig")!
        let update = AppModel.update(
            state: state,
            action: .showRenameSheet(link),
            environment: environment
        )

        XCTAssertEqual(
            update.state.isRenameSheetShowing,
            true,
            "Rename sheet is shown"
        )
        XCTAssertEqual(
            update.state.entryToRename,
            link,
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
            update.state.entryToRename,
            nil,
            "slugToRename was set"
        )
    }
    
    func testRenameField() throws {
        let state = AppModel(
            entryToRename: EntryLink(
                title: "Dawson spoke and there was music"
            )!
        )
        let update = AppModel.update(
            state: state,
            action: .setRenameField("Two pink faces turned in the flare of the tiny torch"),
            environment: environment
        )

        XCTAssertEqual(
            update.state.renameField,
            "Two pink faces turned in the flare of the tiny torch",
            "Rename field set to literal text of query"
        )
    }

    func testSetSearch() throws {
        let state = AppModel()
        let update = AppModel.update(
            state: state,
            action: .setSearch("I Summon my Corn Demon"),
            environment: environment
        )

        XCTAssertEqual(
            update.state.searchText,
            "I Summon my Corn Demon",
            "Set search returns same string"
        )
    }
    
    func testHideSearch() throws {
        let state = AppModel()
        let update = AppModel.update(
            state: state,
            action: .hideSearch,
            environment: environment
        )

        XCTAssertEqual(
            update.state.isSearchShowing,
            false,
            "SearchShowing is false"
        )
        
        XCTAssertEqual(
            update.state.searchText,
            "",
            "Search Text Returns Blank"
        )
    }

    func testSave() throws {
        let state = AppModel(
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("floop-the-pig")!
                ),
                saveState: .modified
            )
        )
        let update = AppModel.update(
            state: state,
            action: .save,
            environment: environment
        )
        XCTAssertEqual(
            update.state.editor.saveState,
            .saving,
            "Sets editor save state to saving when not already saved"
        )
    }

    func testSaveAlreadySaved() throws {
        let state = AppModel(
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("floop-the-pig")!
                ),
                saveState: .saved
            )
        )
        let update = AppModel.update(
            state: state,
            action: .save,
            environment: environment
        )
        XCTAssertEqual(
            update.state.editor.saveState,
            .saved,
            "Leaves editor save state as saved if already saved"
        )
    }

    func testEditorSnapshotModified() throws {
        let state = AppModel(
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("floop-the-pig")!
                ),
                saveState: .saved
            )
        )
        guard let entry = AppModel.snapshotEditor(state.editor) else {
            XCTFail("Failed to derive entry from editor")
            return
        }
        XCTAssertNotNil(
            entry.headers["Modified"],
            "Marks modified time"
        )
    }
}
