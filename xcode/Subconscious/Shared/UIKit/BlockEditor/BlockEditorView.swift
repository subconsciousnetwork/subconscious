//
//  BlockEditorView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/22/23.
//

import SwiftUI
import ObservableStore

extension BlockEditor {
    /// Block editor
    /// This is the top level view for the block editor and coordinates between
    /// the UIKit code (wrapped in `BlockEditor.Representable`) and other
    /// supporting SwiftUI views that don't need to be part of the UIKit code.
    struct BlockEditorView: View {
        @ObservedObject var store: Store<BlockEditor.Model>

        var body: some View {
            ZStack {
                BlockEditor.BlockEditorRepresentable(store: store)
                    .zIndex(0)
                BlockEditor.BlockSelectMenuFrameView(
                    send: { action in }
                )
                .zIndex(1)
            }
        }
    }
}

struct BlockEditorBlockEditorView_Previews: PreviewProvider {
    static var store = Store(
        state: BlockEditor.Model(),
        environment: AppEnvironment()
    )
    
    static var previews: some View {
        BlockEditor.BlockEditorView(store: store)
    }
}
