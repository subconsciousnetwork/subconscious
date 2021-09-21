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
    var size: CGSize

    var body: some View {
        GrowableTextViewRepresentable(
            attributedText: $editor.attributedText,
            isFocused: $editor.isFocused,
            selection: $editor.selection,
            fixedWidth: size.width
        )
        .insets(
            EdgeInsets(
                top: AppTheme.padding,
                leading: AppTheme.padding,
                bottom: AppTheme.padding,
                trailing: AppTheme.padding
            )
        )
        .frame(minHeight: size.height)
    }
}
