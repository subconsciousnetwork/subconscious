//
//  BlockEditorRepresentable.swift
//  SubconsciousExperiments
//
//  Created by Gordon Brander on 6/6/23.
//

import SwiftUI
import Combine
import os

typealias BlockEditorStore = ControllerStore.Store<BlockEditor.ViewController>

extension BlockEditor {
    // MARK: View Representable
    struct Representable: UIViewControllerRepresentable {
        @ObservedObject var store: BlockEditorStore
        
        func makeCoordinator() -> Coordinator {
            Coordinator(store: store)
        }
        
        func makeUIViewController(context: Context) -> ViewController {
            ViewController(
                store: context.coordinator.store
            )
        }
        
        func updateUIViewController(
            _ uiViewController: ViewController,
            context: Context
        ) {}
        
        /// The coordinator acts as a delegate and coordinator between the
        /// SwiftUI representable, and the UIViewController.
        class Coordinator: NSObject {
            private var controllerStoreChanges: AnyCancellable?
            var store: BlockEditorStore
            
            init(store: BlockEditorStore) {
                self.store = store
                super.init()
            }
        }
    }
}

struct BlockStackEditorViewControllerRepresentable_Previews: PreviewProvider {
    struct TestView: View {
        @StateObject private var store = BlockEditorStore(
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
