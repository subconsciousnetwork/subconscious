//
//  BlockEditorBlockSelectMenuFrame.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/21/23.
//

import SwiftUI
import ObservableStore

extension BlockEditor {
    struct BlockSelectMenuFrameView: View {
        @GestureState private var dragGesture: CGFloat = 0
        @ObservedObject var store: Store<BlockEditor.Model>
        /// Threshold at which gesture is interpreted as a dismiss
        var dragThreshold: CGFloat = 80
        /// Distance when dismissed
        var dismissedOffsetY: CGFloat = 300

        var dragOffsetY: CGFloat {
            if store.state.isBlockSelectMenuPresented {
                return 0
            }
            return dismissedOffsetY
        }


        private func setPresented(isPresented: Bool) {
            if !isPresented {
                self.store.send(.exitBlockSelectMode)
            }
        }

        var body: some View {
            VStack {
                Spacer()
                BlockEditor.BlockSelectMenuView(
                    store: store
                )
                .animation(.interactiveSpring(), value: dragGesture)
                .offset(y: dragOffsetY + dragGesture)
                .gesture(
                    DragGesture()
                        .updating($dragGesture) { gesture, state, _ in
                            state = gesture.translation.height
                        }
                        .onEnded { gesture in
                            self.setPresented(
                                isPresented:
                                    gesture.predictedEndTranslation.height <
                                    dragThreshold
                            )
                        }
                )
            }
            .padding(AppTheme.padding)
        }
    }
}

struct BlockEditorBlockSelectMenuFrameView_Previews: PreviewProvider {
    static var previews: some View {
        BlockEditor.BlockSelectMenuFrameView(
            store: Store(
                state: BlockEditor.Model(),
                environment: AppEnvironment()
            )
        )
    }
}
