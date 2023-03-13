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
        let state = MemoEditorDetailModel()
        
        let modified = Date.now
        
        let entry = MemoEntry(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: modified,
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Example text"
            )
        )
        
        let detail = EntryDetail(
            saveState: .saved,
            entry: entry
        )
        
        let update = MemoEditorDetailModel.update(
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
            update.state.editor.text,
            "Example text",
            "Sets editor text"
        )
        XCTAssertEqual(
            update.state.editor.focusRequest,
            true,
            "Focus request is set to true"
        )
    }
    
    func testUpdateDetailFocus() throws {
        let store = Store(
            state: MemoEditorDetailModel(),
            environment: environment
        )
        
        let entry = MemoEntry(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
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
                store.state.editor.focusRequest,
                true,
                "Autofocus sets editor focus"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)
    }
    
    func testUpdateDetailBlur() throws {
        let state = MemoEditorDetailModel()
        
        let entry = MemoEntry(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Example"
            )
        )
        
        let detail = EntryDetail(
            saveState: .saved,
            entry: entry
        )
        
        let update = MemoEditorDetailModel.update(
            state: state,
            action: .setDetail(
                detail: detail,
                autofocus: false
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.editor.focusRequest,
            false,
            "Autofocus sets editor focus"
        )
    }
    
    func testAutosave() throws {
        let state = MemoEditorDetailModel(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            saveState: .unsaved
        )
        let update = MemoEditorDetailModel.update(
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
        let state = MemoEditorDetailModel(
            address: Slug(formatting: "example")!.toPublicMemoAddress(),
            saveState: .saved
        )
        let update = MemoEditorDetailModel.update(
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
        let state = MemoEditorDetailModel(
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
    
    func testSucceedMoveEntry() throws {
        let from = MemoAddress.public(Slashlink("/loomings")!)
        let to = MemoAddress.public(Slashlink("/the-lee-tide")!)

        let state = MemoEditorDetailModel(
            address: from,
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                fileExtension: ContentType.subtext.fileExtension
            )
        )
        let update = MemoEditorDetailModel.update(
            state: state,
            action: .succeedMoveEntry(
                from: from,
                to: to
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            to,
            "Changes address"
        )
    }
    
    func testSucceedMoveEntryMismatch() throws {
        let state = MemoEditorDetailModel(
            address: Slug(formatting: "loomings")!.toPublicMemoAddress(),
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                fileExtension: ContentType.subtext.fileExtension
            )
        )
        let update = MemoEditorDetailModel.update(
            state: state,
            action: .succeedMoveEntry(
                from: MemoAddress.public(Slashlink("/the-white-whale")!),
                to: MemoAddress.public(Slashlink("/the-lee-tide")!)
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            Slug(formatting: "loomings")!.toPublicMemoAddress(),
            "Does not change address, because addresses don't match"
        )
    }
    
    func testSucceedMergeEntry() throws {
        let address = Slug(formatting: "loomings")!.toPublicMemoAddress()
        let state = MemoEditorDetailModel(
            address: address,
            headers: WellKnownHeaders(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                fileExtension: ContentType.subtext.fileExtension
            )
        )

        let parent = MemoAddress.public(Slashlink("/the-lee-tide")!)

        let update = MemoEditorDetailModel.update(
            state: state,
            action: .succeedMergeEntry(
                parent: parent,
                child: address
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.address,
            parent,
            "Changes address"
        )
    }
}
