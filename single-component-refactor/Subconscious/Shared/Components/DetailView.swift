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
    var onBacklinkTap: (String) -> Void

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
                            action: onBacklinkTap
                        )
                    }
                }
                KeyboardToolbarView(
                    suggestions: []
                )
            }
        }
    }
}
