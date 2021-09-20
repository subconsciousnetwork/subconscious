//
//  EditorView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import Combine

struct EditorView: View {
    @Binding var editor: EditorModel
    var fixedWidth: CGFloat

    var body: some View {
        GrowableTextViewRepresentable(
            attributedText: $editor.attributedText,
            isFocused: $editor.isFocused,
            selection: $editor.selection,
            fixedWidth: fixedWidth
        )
        .insets(
            EdgeInsets(
                top: AppTheme.unit2,
                leading: AppTheme.unit2,
                bottom: AppTheme.unit2,
                trailing: AppTheme.unit2
            )
        )
    }
}
