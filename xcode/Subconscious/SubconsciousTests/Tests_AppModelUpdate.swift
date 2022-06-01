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
            update.state.entryToRename,
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
            update.state.entryToRename,
            nil,
            "slugToRename was set"
        )
    }
    
    func testRenameField() throws {
        let state = AppModel()
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

    func testSaveMendHeaders() throws {
        let state = AppModel(
            editor: Editor(
                entryInfo: EditorEntryInfo(
                    slug: Slug("floop-the-pig")!,
                    headers: HeaderIndex(
                        [
                            Header(name: "Author", value: "Finn the Human")
                        ]
                    )
                ),
                saveState: .modified
            )
        )
        let update = AppModel.update(
            state: state,
            action: .save,
            environment: environment
        )
        guard let entryInfo = update.state.editor.entryInfo else {
            XCTFail("No entry info found")
            return
        }
        XCTAssertEqual(
            entryInfo.headers["content-type"],
            "text/subtext",
            "Sets default headers"
        )
        XCTAssertEqual(
            entryInfo.headers["title"],
            "Floop the pig",
            "Sets default headers"
        )
        XCTAssertNotNil(
            entryInfo.headers["modified"],
            "Sets default headers"
        )
        XCTAssertNotNil(
            entryInfo.headers["created"],
            "Sets default headers"
        )
        XCTAssertEqual(
            entryInfo.headers["author"],
            "Finn the Human",
            "Retains existing headers"
        )
    }

    func testSaveMendHeadersModifiedCreated() throws {
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
        var next = update.state
        guard let entryInfo = update.state.editor.entryInfo else {
            XCTFail("No entry info found")
            return
        }
        let modified = entryInfo.headers["modified"]
        let created = entryInfo.headers["created"]
        next.editor.saveState = .modified
        
        let expectation = XCTestExpectation(
            description: "Second save"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let update = AppModel.update(
                state: next,
                action: .save,
                environment: self.environment
            )
            guard let entryInfo = update.state.editor.entryInfo else {
                XCTFail("No entry info found")
                return
            }
            XCTAssertNotEqual(
                modified,
                entryInfo.headers["modified"],
                "Modified header is updated on save"
            )
            XCTAssertEqual(
                created,
                entryInfo.headers["created"],
                "Created header remains the same"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.1)
    }
}
