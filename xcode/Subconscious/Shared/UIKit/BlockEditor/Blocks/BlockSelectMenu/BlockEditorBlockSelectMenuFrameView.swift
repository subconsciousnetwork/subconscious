//
//  BlockEditorBlockSelectMenuFrame.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/21/23.
//

import SwiftUI

extension BlockEditor {
    struct BlockEditorBlockSelectMenuFrameView: View {
        @State private var dragOffsetY: CGFloat = 0
        @GestureState private var dragGesture: CGFloat = 0
        var dragThreshold: CGFloat = 100
        var send: (BlockSelectMenuAction) -> Void

        var body: some View {
            VStack {
                Spacer()
                BlockEditor.BlockSelectMenuView(
                    send: send
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
        }
    }
}

struct BlockEditorBlockSelectMenuFrameView_Previews: PreviewProvider {
    static var previews: some View {
        BlockEditor.BlockEditorBlockSelectMenuFrameView(
            send: { action in }
        )
    }
}
