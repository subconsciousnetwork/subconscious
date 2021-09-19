//
//  EditorView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import Combine
import os

struct EditorView: View {
    @Binding var editor: EditorModel

    var body: some View {
        GeometryReader { geometry in
            VStack {
                GrowableTextViewRepresentable(
                    attributedText: $editor.attributedText,
                    isFocused: $editor.isFocused,
                    selection: $editor.selection,
                    fixedWidth: geometry.size.width
                )
            }
        }
    }
}
