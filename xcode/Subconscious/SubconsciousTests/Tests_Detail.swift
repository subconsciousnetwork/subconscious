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
    
    func testSetAndPresentDetail() throws {
        let state = DetailModel()
        
        let modified = Date.now
        
        let entry = MemoEntry(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: modified,
                title: "Example",
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Example text"
            )
        )
        
        let detail = EntryDetail(
            saveState: .saved,
            entry: entry
        )
        
        let update = DetailModel.update(
            state: state,
            action: .setDetail(
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
            update.state.headers.modified,
            modified,
            "Modified is set from entry"
        )
        XCTAssertEqual(
            update.state.address,
            detail.entry.address,
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
        
        let entry = MemoEntry(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Example",
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Example"
            )
        )
        
        let detail = EntryDetail(
            saveState: .saved,
            entry: entry
        )
        
        store.send(.setDetail(detail: detail, autofocus: true))
        
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
        
        let entry = MemoEntry(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Example",
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Example"
            )
        )
        
        let detail = EntryDetail(
            saveState: .saved,
            entry: entry
        )
        
        let update = DetailModel.update(
            state: state,
            action: .setDetail(
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
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
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
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
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
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            saveState: .saved
        )
        guard let entry = state.snapshotEntry() else {
            XCTFail("Failed to derive entry from editor")
            return
        }
        let interval = Date.now.timeIntervalSince(entry.contents.modified)
        XCTAssert(
            interval < 1,
            "Marks modified time"
        )
    }
    
    func testShowRenameSheet() throws {
        let state = DetailModel()
        let link = EntryLink(title: "Loomings", audience: .public)!
        let update = DetailModel.update(
            state: state,
            action: .presentRenameSheet(
                address: link.address,
                title: link.title
            ),
            environment: environment
        )
        
        XCTAssertEqual(
            update.state.isRenameSheetPresented,
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
            action: .unpresentRenameSheet,
            environment: environment
        )
        
        XCTAssertEqual(
            update.state.isRenameSheetPresented,
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
                title: "Dawson spoke and there was music",
                audience: .public
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
    
    func testSucceedMoveEntry() throws {
        let from = Slug(formatting: "loomings")!
            .toPublicMemoAddress()
            .toEntryLink()
        let to = Slug(formatting: "The lee tide")!
            .toPublicMemoAddress()
            .toEntryLink(title: "The Lee Tide")
        let state = DetailModel(
            address: from.address,
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Loomings",
                fileExtension: ContentType.subtext.fileExtension
            )
        )
        let update = DetailModel.update(
            state: state,
            action: .succeedMoveEntry(
                from: from,
                to: to
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            to.address,
            "Changes address"
        )
        XCTAssertEqual(
            update.state.headers.title,
            "The Lee Tide",
            "Changes title"
        )
    }
    
    func testSucceedMoveEntryMismatch() throws {
        let state = DetailModel(
            address: Slug(formatting: "loomings")!.toPublicMemoAddress(),
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Loomings",
                fileExtension: ContentType.subtext.fileExtension
            )
        )
        let update = DetailModel.update(
            state: state,
            action: .succeedMoveEntry(
                from: Slug(formatting: "The White Whale")!
                    .toPublicMemoAddress()
                    .toEntryLink(),
                to: Slug(formatting: "The Lee Tide")!
                    .toPublicMemoAddress()
                    .toEntryLink()
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            Slug(formatting: "loomings")!.toPublicMemoAddress(),
            "Does not change address, because addresses don't match"
        )
        XCTAssertEqual(
            update.state.headers.title,
            "Loomings",
            "Does not change title, because addresses don't match"
        )
    }
    
    func testSucceedRetitleEntry() throws {
        let address = Slug(formatting: "loomings")!.toPublicMemoAddress()
        let state = DetailModel(
            address: address,
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Loomings",
                fileExtension: ContentType.subtext.fileExtension
            )
        )
        let update = DetailModel.update(
            state: state,
            action: .succeedRetitleEntry(
                from: address.toEntryLink(title: "Loomings"),
                to: address.toEntryLink(title: "LOOMINGS")
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            address,
            "Does not change address"
        )
        XCTAssertEqual(
            update.state.headers.title,
            "LOOMINGS",
            "Changes title"
        )
    }
    
    /// Tests against a mis-matched from/to slug
    func testSucceedRetitleEntryMismatch() throws {
        let address = Slug(formatting: "loomings")!.toPublicMemoAddress()
        let state = DetailModel(
            address: address,
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Loomings",
                fileExtension: ContentType.subtext.fileExtension
            )
        )
        let update = DetailModel.update(
            state: state,
            action: .succeedRetitleEntry(
                from: Slug(formatting: "wrong")!
                    .toPublicMemoAddress()
                    .toEntryLink(title: "Wrong"),
                to: Slug(formatting: "wrong")!
                    .toPublicMemoAddress()
                    .toEntryLink(title: "WRONG")
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            address,
            "Does not change address"
        )
        XCTAssertEqual(
            update.state.headers.title,
            "Loomings",
            "Does not change title, because addresses don't match"
        )
    }
    
    func testSucceedMergeEntry() throws {
        let address = Slug(formatting: "loomings")!.toPublicMemoAddress()
        let state = DetailModel(
            address: address,
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Loomings",
                fileExtension: ContentType.subtext.fileExtension
            )
        )

        let parentLink = Slug(formatting: "The Lee Tide")!
            .toPublicMemoAddress()
            .toEntryLink(title: "The Lee Tide")

        let update = DetailModel.update(
            state: state,
            action: .succeedMergeEntry(
                parent: parentLink,
                child: address.toEntryLink()
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            parentLink.address,
            "Changes address"
        )
        XCTAssertEqual(
            update.state.headers.title,
            "The Lee Tide",
            "Changes title"
        )
    }
}
