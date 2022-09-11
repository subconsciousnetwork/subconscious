//
//  TestsViewStore.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/12/22.
//

import XCTest
import ObservableStore
@testable import Subconscious

class TestsViewStore: XCTestCase {
    enum ParentAction {
        case edit(String)
    }

    struct ParentEnvironment {}

    struct ParentModel: Hashable {
        var text: String = ""
        var edits: Int = 0

        static func update(
            state: ParentModel,
            action: ParentAction,
            environment: ParentEnvironment
        ) -> Update<ParentModel, ParentAction> {
            switch action {
            case .edit(let string):
                var model = state
                model.text = string
                model.edits = model.edits + 1
                return Update(state: model)
            }
        }
    }

    struct ChildModel: Hashable {
        var text: String
    }

    enum ChildAction {
        case setText(String)
    }

    func testViewStore() throws {
        let store = Store(
            update: ParentModel.update,
            state: ParentModel(),
            environment: ParentEnvironment()
        )

        let viewStore: ViewStore<ChildModel, ChildAction> = ViewStore(
            store: store,
            get: { model in
                ChildModel(text: model.text)
            },
            tag: { action in
                switch action {
                case .setText(let string):
                    return .edit(string)
                }
            }
        )

        viewStore.send(.setText("Foo"))
        viewStore.send(.setText("Bar"))
        XCTAssertEqual(
            viewStore.state.text,
            "Bar"
        )
        XCTAssertEqual(
            store.state.text,
            "Bar"
        )
        XCTAssertEqual(
            store.state.edits,
            2
        )
    }
}
