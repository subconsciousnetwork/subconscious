//
//  BlockEditorRepresentable.swift
//  SubconsciousExperiments
//
//  Created by Gordon Brander on 6/6/23.
//

import SwiftUI
import Combine
import ObservableStore
import os

extension BlockEditor {
    // MARK: View Representable
    struct Representable: UIViewControllerRepresentable {
        static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditor.Representable"
        )
        
        @ObservedObject var store: Store<BlockEditor.Model>
        
        func makeCoordinator() -> Coordinator {
            Coordinator(store: store)
        }
        
        func makeUIViewController(context: Context) -> ViewController {
            Self.logger.debug("makeUIViewController")
            return ViewController(
                state: store.state,
                send: context.coordinator.store.send(onMainActor:)
            )
        }
        
        func updateUIViewController(
            _ uiViewController: ViewController,
            context: Context
        ) {
            Self.logger.debug("updateUIViewController")
            uiViewController.update(context.coordinator.store.state)
        }
        
        /// The coordinator acts as a delegate and coordinator between the
        /// SwiftUI representable, and the UIViewController.
        class Coordinator: NSObject {
            private var controllerStoreChanges: AnyCancellable?
            var store: Store<BlockEditor.Model>
            
            init(store: Store<BlockEditor.Model>) {
                self.store = store
                super.init()
            }
        }
    }
}

struct BlockStackEditorViewControllerRepresentable_Previews: PreviewProvider {
    struct TestView: View {
        @StateObject private var store = Store<BlockEditor.Model>(
            state: BlockEditor.Model(
                blocks: [
                    BlockEditor.BlockModel.heading(
                        BlockEditor.TextBlockModel(
                            text: "Foo"
                        )
                    ),
                    BlockEditor.BlockModel.text(
                        BlockEditor.TextBlockModel(
                            text: "Bar"
                        )
                    )
                ]
            ),
            environment: AppEnvironment.default
        )
        
        var body: some View {
            BlockEditor.Representable(store: store)
        }
    }

    static var previews: some View {
        TestView()
    }
}
