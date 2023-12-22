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
        @State private var dragOffsetY: CGFloat = 0
        @GestureState private var dragGesture: CGFloat = 0
        @ObservedObject var store: Store<BlockEditor.Model>
        var dragThreshold: CGFloat = 100

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
                        .updating(
                            $dragGesture,
                            body: { gesture, state, transaction in
                                state = gesture.translation.height
                            }
                        )
                        .onEnded({ gesture in
                            if gesture.predictedEndTranslation.height >
                                dragThreshold
                            {
                                self.dragOffsetY = 300
                            } else {
                                self.dragOffsetY = 0
                            }
                        })
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
