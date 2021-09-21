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
    var onActivateBacklink: (String) -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    VStack {
                        EditorView(
                            editor: $editor,
                            fixedWidth: geometry.size.width
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
                        action: {
                            editor.isFocused = false
                        },
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
