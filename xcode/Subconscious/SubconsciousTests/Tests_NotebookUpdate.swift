//
//  Tests_NotebookUpdate.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 8/30/22.
//

import XCTest
@testable import Subconscious

/// Tests for Notebook.update
class Tests_NotebookUpdate: XCTestCase {
    let environment = AppEnvironment()

    func testUpdateDetail() throws {
        let state = NotebookModel()
        let slug = try Slug("example").unwrap()
        let detail = EntryDetail(
            saveState: .saved,
            entry: SubtextFile(
                slug: slug,
                content: "Example text"
            )
        )
        let update = NotebookModel.update(
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

    func testSave() throws {
        let state = NotebookModel(
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("floop-the-pig")!
                ),
                saveState: .modified
            )
        )
        let update = NotebookModel.update(
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
        let state = NotebookModel(
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("floop-the-pig")!
                ),
                saveState: .saved
            )
        )
        let update = NotebookModel.update(
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
        let state = NotebookModel(
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("floop-the-pig")!
                ),
                saveState: .saved
            )
        )
        guard let entry = NotebookModel.snapshotEditor(state.editor) else {
            XCTFail("Failed to derive entry from editor")
            return
        }
        XCTAssertNotNil(
            entry.headers["Modified"],
            "Marks modified time"
        )
    }
}
