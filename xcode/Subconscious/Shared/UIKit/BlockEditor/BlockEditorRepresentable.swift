//
//  BlockEditorRepresentable.swift
//  SubconsciousExperiments
//
//  Created by Gordon Brander on 6/6/23.
//

import SwiftUI
import Combine
import os

extension BlockEditor {
    // MARK: View Representable
    struct Representable: UIViewControllerRepresentable {
        @Binding var state: Model
        
        func makeCoordinator() -> Coordinator {
            Coordinator(state: self.$state)
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
                state: context.coordinator.state
            )
        }
        
        /// The coordinator acts as a delegate and coordinator between the
        /// SwiftUI representable, and the UIViewController.
        class Coordinator: NSObject {
            private var controllerStoreChanges: AnyCancellable?
            /// Reference to the outer `@State` variable
            @Binding var state: Model
            var store: ControllerStore.Store<ViewController>
            
            init(state: Binding<Model>) {
                self._state = state
                self.store = ControllerStore.Store(
                    state: state.wrappedValue
                )
                super.init()
                // Replay internal changes to state on to SwiftUI binding
                // We debounce the updates so that at most, we get one state
                // change every half second.
                self.controllerStoreChanges = self.store.changes
                    .debounce(
                        for: .seconds(0.5),
                        scheduler: DispatchQueue.main
                    )
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] state in
                        self?.state = state
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
