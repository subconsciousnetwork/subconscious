//
//  Tests_NotebookUpdate.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 8/30/22.
//

import XCTest
import ObservableStore
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
            update.state.detail.isLoading,
            false,
            "isDetailLoading set to false"
        )
        XCTAssertEqual(
            update.state.detail.slug,
            detail.slug,
            "Sets the slug"
        )
        XCTAssertEqual(
            update.state.detail.markupEditor.text,
            "Example text",
            "Sets editor text"
        )
    }

    func testUpdateDetailFocus() throws {
        let store = Store(
            update: NotebookModel.update,
            state: NotebookModel(),
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

        store.send(.updateDetail(detail: detail, autofocus: true))

        let expectation = XCTestExpectation(
            description: "Autofocus sets editor focus"
        )
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            XCTAssertEqual(
                store.state.detail.markupEditor.focusRequest,
                true,
                "Autofocus sets editor focus"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)
    }

    func testUpdateDetailBlur() throws {
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
                autofocus: false
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.detail.markupEditor.focusRequest,
            false,
            "Autofocus sets editor focus"
        )
    }

    func testEntryCount() throws {
        let state = NotebookModel()
        let update = NotebookModel.update(
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
        let state = NotebookModel(
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
        let update = NotebookModel.update(
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
}
