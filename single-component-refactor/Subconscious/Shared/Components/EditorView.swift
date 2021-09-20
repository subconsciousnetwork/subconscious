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
                .insets(
                    EdgeInsets(
                        top: 16,
                        leading: 16,
                        bottom: 16,
                        trailing: 16
                    )
                )
                //  TODO: set explicit line height via attributedString
                .frame(minHeight: 29 * 16)
            }
        }
    }
}
