//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailView: View {
    @Binding var editor: EditorModel
    var backlinks: [TextFile]
    var onDone: () -> Void
    var onEditorLink: (
        URL,
        NSAttributedString,
        NSRange,
        UITextItemInteraction
    ) -> Bool
    var onActivateBacklink: (String) -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        EditorView(
                            editor: $editor,
                            onLink: onEditorLink,
                            size: CGSize(
                                width: geometry.size.width,
                                height: (
                                    geometry.size.height -
                                    AppTheme.icon -
                                    (AppTheme.tightPadding * 2) -
                                    (AppTheme.unit4)
                                )
                            )
                        )
                        Divider()
                        BacklinksView(
                            backlinks: backlinks,
                            onActivateBacklink: onActivateBacklink
                        )
                    }
                }
                if editor.isFocused {
                    KeyboardToolbarView(
                        suggestion: "An organism is a living system maintaining both a higher level of internal cooperation"
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.default, value: editor.isFocused)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if editor.isFocused {
                    Button(
                        action: onDone,
                        label: {
                            Text("Done")
                        }
                    )
                } else {
                    EmptyView()
                }
            }
        }
    }
}
