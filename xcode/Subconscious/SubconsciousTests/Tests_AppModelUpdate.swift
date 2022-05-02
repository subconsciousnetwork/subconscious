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
}
