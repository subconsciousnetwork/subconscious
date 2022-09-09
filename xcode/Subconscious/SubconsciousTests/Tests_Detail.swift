//
//  Tests_Detail.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 9/9/22.
//

import XCTest
import ObservableStore
@testable import Subconscious

class Tests_Detail: XCTestCase {
    let environment = AppEnvironment()

    func testAutosave() throws {
        let state = DetailModel(
            slug: Slug("floop-the-pig")!,
            saveState: .modified
        )
        let update = DetailModel.update(
            state: state,
            action: .autosave,
            environment: environment
        )
        XCTAssertEqual(
            update.state.saveState,
            .saving,
            "Sets editor save state to saving when not already saved"
        )
    }

    func testSaveAlreadySaved() throws {
        let state = DetailModel(
            slug: Slug("floop-the-pig")!,
            saveState: .saved
        )
        let update = DetailModel.update(
            state: state,
            action: .autosave,
            environment: environment
        )
        XCTAssertEqual(
            update.state.saveState,
            .saved,
            "Leaves editor save state as saved if already saved"
        )
    }

    func testEditorSnapshotModified() throws {
        let state = DetailModel(
            slug: Slug("floop-the-pig")!,
            saveState: .saved
        )
        guard let entry = state.snapshotEntry() else {
            XCTFail("Failed to derive entry from editor")
            return
        }
        XCTAssertNotNil(
            entry.headers["Modified"],
            "Marks modified time"
        )
    }

    func testSetEditorFocus() {
        let store = Store(
            update: DetailModel.update,
            state: DetailModel(
                slug: Slug("great-expectations")!,
                saveState: .modified,
                isLoading: false,
                markupEditor: MarkupTextModel(
                    text: "Mr. Pumblechook’s premises in the High Street of the market town, were of a peppercorny and farinaceous character."
                )
            ),
            environment: environment
        )

        store.send(.requestEditorFocus(true))

        let expectation = XCTestExpectation(
            description: "focus set to nil"
        )
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            XCTAssertEqual(
                store.state.markupEditor.focusRequest,
                true,
                "Focus request was set"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)
    }


    func testShowRenameSheet() throws {
        let state = DetailModel()
        let link = EntryLink(title: "Floop the Pig")!
        let update = DetailModel.update(
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
        let state = DetailModel()
        let update = DetailModel.update(
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
        let state = DetailModel(
            entryToRename: EntryLink(
                title: "Dawson spoke and there was music"
            )!
        )
        let update = DetailModel.update(
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

}
