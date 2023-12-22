//
//  BlockEditorRepresentable.swift
//  SubconsciousExperiments
//
//  Created by Gordon Brander on 6/6/23.
//

import SwiftUI
import Combine
import os
import ObservableStore

extension BlockEditor {
    // MARK: View Representable
    struct BlockEditorRepresentable: UIViewControllerRepresentable {
        @ObservedObject var store: Store<BlockEditor.Model>
        
        func makeCoordinator() -> Coordinator {
            Coordinator(store: store)
        }
        
        func makeUIViewController(context: Context) -> ViewController {
            ViewController(
                store: store
            )
        }
        
        func updateUIViewController(
            _ uiViewController: ViewController,
            context: Context
        ) {
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
        @StateObject private var store = Store(
            state: BlockEditor.Model(
                blocks: BlockEditor.BlocksModel(
                    blocks:[
                        BlockEditor.BlockModel.heading(
                            BlockEditor.TextBlockModel(
                                dom: Subtext(markup: "Foo")
                            )
                        ),
                        BlockEditor.BlockModel.text(
                            BlockEditor.TextBlockModel(
                                dom: Subtext(markup: "Bar")
                            )
                        )
                    ]
                )
            ),
            environment: AppEnvironment.default
        )

        var body: some View {
            BlockEditor.BlockEditorRepresentable(
                store: store
            )
        }
    }

    static var previews: some View {
        TestView()
    }
}
