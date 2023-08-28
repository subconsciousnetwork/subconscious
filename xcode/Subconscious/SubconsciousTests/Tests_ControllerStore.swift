//
//  Tests_ControllerStore.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 8/28/23.
//

import XCTest
import UIKit
@testable import Subconscious

final class Tests_ControllerStore: XCTestCase {
    enum TestAction: Hashable {
        case setText(String)
    }

    struct TestModel: Hashable {
        var text: String = ""
    }

    class TestViewController: UIViewController, ControllerStoreControllerProtocol {
        typealias Model = TestModel
        typealias Action = TestAction
        
        lazy var textView = UITextView(frame: .zero)

        override func viewDidLoad() {
            view.addSubview(textView)
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                textView.topAnchor.constraint(equalTo: view.topAnchor),
                textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        @MainActor
        func reconfigure(
            state: TestModel,
            send: @escaping (TestAction) -> Void
        ) {
            self.textView.text = state.text
        }

        @MainActor
        func update(
            state: TestModel,
            action: TestAction
        ) -> Update {
            switch action {
            case .setText(let text):
                return setText(state: state, text: text)
            }
        }

        func setText(
            state: TestModel,
            text: String
        ) -> Update {
            var model = state
            model.text = text
            
            let render = {
                self.textView.text = text
            }
            
            return Update(state: model, render: render)
        }
    }

    @MainActor
    func testUpdatesStateAndRunsRender() throws {
        let store = ControllerStore.Store<TestViewController>(
            state: TestModel()
        )
        let controller = TestViewController()
        store.connect(controller)
        
        store.transact(TestAction.setText("Foo"))
        XCTAssertEqual(store.state.text, "Foo", "Store updates state")
        XCTAssertEqual(controller.textView.text, "Foo", "Store renders text")
    }
}
