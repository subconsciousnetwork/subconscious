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

    func testsetAndPresentDetail() throws {
        let state = DetailModel()
        let slug = try Slug("example").unwrap()
        let modified = Date.now

        let entry = SubtextFile(
            slug: slug,
            content: "Example text"
        )
        .modified(modified)

        let detail = EntryDetail(
            saveState: .saved,
            entry: entry
        )

        let update = DetailModel.update(
            state: state,
            action: .setAndPresentDetail(
                detail: detail,
                autofocus: true
            ),
            environment: environment
        )

        XCTAssertEqual(
            update.state.isLoading,
            false,
            "isDetailLoading set to false"
        )
        XCTAssertEqual(
            update.state.modified == modified,
            false,
            "Modified is set from entry"
        )
        XCTAssertEqual(
            update.state.slug,
            detail.slug,
            "Sets the slug"
        )
        XCTAssertEqual(
            update.state.markupEditor.text,
            "Example text",
            "Sets editor text"
        )
        XCTAssertEqual(
            update.state.markupEditor.focusRequest,
            true,
            "Focus request is set to true"
        )
    }

    func testUpdateDetailFocus() throws {
        let store = Store(
            state: DetailModel(),
            environment: environment
        )

        let slug = try Slug("example").unwrap()
        let detail = EntryDetail(
            saveState: .saved,
            entry: SubtextFile(
                slug: slug,
                content: "Example text"
            )
        )

        store.send(.setAndPresentDetail(detail: detail, autofocus: true))

        let expectation = XCTestExpectation(
            description: "Autofocus sets editor focus"
        )
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            XCTAssertEqual(
                store.state.markupEditor.focusRequest,
                true,
                "Autofocus sets editor focus"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)
    }

    func testUpdateDetailBlur() throws {
        let state = DetailModel()
        let slug = try Slug("example").unwrap()
        let detail = EntryDetail(
            saveState: .saved,
            entry: SubtextFile(
                slug: slug,
                content: "Example text"
            )
        )
        let update = DetailModel.update(
            state: state,
            action: .setAndPresentDetail(
                detail: detail,
                autofocus: false
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.markupEditor.focusRequest,
            false,
            "Autofocus sets editor focus"
        )
    }

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

    func testDetailActionFromEntrySuggestion() throws {
        let entrySuggestion = Suggestion.entry(
            EntryLink(title: "Systems Generating Systems")!
        )
        let action = DetailAction.fromSuggestion(entrySuggestion)

        XCTAssertEqual(
            action,
            DetailAction.loadAndPresentDetail(
                link: EntryLink(title: "Systems Generating Systems")!,
                fallback: "Systems Generating Systems",
                autofocus: false
            )
        )
    }

    func testDetailActionFromSearchSuggestion() throws {
        let entrySuggestion = Suggestion.search(
            EntryLink(
                slug: Slug("systems-generating-systems")!,
                title: "Systems Generating Systems"
            )
        )
        let action = DetailAction.fromSuggestion(entrySuggestion)

        XCTAssertEqual(
            action,
            DetailAction.loadAndPresentDetail(
                link: EntryLink(title: "Systems Generating Systems")!,
                fallback: "Systems Generating Systems",
                autofocus: true
            )
        )
    }

    func testDetailActionFromJournalSuggestion() throws {
        let entrySuggestion = Suggestion.journal(
            EntryLink(
                slug: Slug("systems-generating-systems")!,
                title: "Systems Generating Systems"
            )
        )
        let action = DetailAction.fromSuggestion(entrySuggestion)

        XCTAssertEqual(
            action,
            DetailAction.loadAndPresentTemplateDetail(
                link: EntryLink(title: "Systems Generating Systems")!,
                template: Config.default.journalTemplate,
                autofocus: true
            )
        )
    }

    func testDetailActionFromScratchSuggestion() throws {
        let entrySuggestion = Suggestion.scratch(
            EntryLink(
                slug: Slug("systems-generating-systems")!,
                title: "Systems Generating Systems"
            )
        )
        let action = DetailAction.fromSuggestion(entrySuggestion)

        XCTAssertEqual(
            action,
            DetailAction.loadAndPresentDetail(
                link: EntryLink(title: "Systems Generating Systems")!,
                fallback: "Systems Generating Systems",
                autofocus: true
            )
        )
    }

    func testDetailActionFromRandomSuggestion() throws {
        let entrySuggestion = Suggestion.random
        let action = DetailAction.fromSuggestion(entrySuggestion)

        XCTAssertEqual(
            action,
            DetailAction.loadAndPresentRandomDetail(autofocus: false)
        )
    }
}
