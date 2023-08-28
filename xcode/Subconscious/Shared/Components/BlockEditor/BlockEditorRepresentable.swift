//
//  BlockStackEditorRepresentable.swift
//  SubconsciousExperiments
//
//  Created by Gordon Brander on 6/6/23.
//

import SwiftUI
import os

extension BlockEditor {
    //  MARK: View Representable
    struct Representable: UIViewControllerRepresentable {
        @Binding var state: Model
        
        func makeCoordinator() -> Coordinator {
            Coordinator(representable: self)
        }
        
        func makeUIViewController(context: Context) -> ViewController {
            ViewController(
                store: context.coordinator.store
            )
        }
        
        func updateUIViewController(
            _ uiViewController: ViewController,
            context: Context
        ) {
            uiViewController.store.reset(
                controller: uiViewController,
                state: context.coordinator.representable.state
            )
        }
        
        /// The coordinator acts as a delegate and coordinator between the
        /// SwiftUI representable, and the UIViewController.
        class Coordinator: NSObject {
            var representable: Representable
            var store: ControllerStore.Store<ViewController>
            
            init(representable: Representable) {
                self.representable = representable
                self.store = ControllerStore.Store(
                    state: representable.state
                )
            }

            func setOuterState(_ state: Model) {
                DispatchQueue.main.async {
                    self.representable.state = state
                }
            }
        }
    }
}

struct BlockStackEditorViewControllerRepresentable_Previews: PreviewProvider {
    struct TestView: View {
        @State private var state = BlockEditor.Model(
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
        )

        var body: some View {
            BlockEditor.Representable(
                state: $state
            )
        }
    }

    static var previews: some View {
        TestView()
    }
}
