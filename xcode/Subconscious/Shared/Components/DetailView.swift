//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailView: View {
    @Binding var editorAttributedText: NSAttributedString
    @Binding var isEditorFocused: Bool
    @Binding var editorSelection: NSRange
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
            PseudoKeyboardToolbarView(
                isKeyboardUp: isEditorFocused,
                content: {
                    ScrollView {
                        VStack(spacing: 0) {
                            GrowableTextViewRepresentable(
                                attributedText: $editorAttributedText,
                                isFocused: $isEditorFocused,
                                selection: $editorSelection,
                                onLink: onEditorLink,
                                fixedWidth: geometry.size.width
                            )
                            .insets(
                                EdgeInsets(
                                    top: AppTheme.padding,
                                    leading: AppTheme.padding,
                                    bottom: AppTheme.padding,
                                    trailing: AppTheme.padding
                                )
                            )
                            .frame(minHeight: geometry.size.height)
                            Divider()
                            BacklinksView(
                                backlinks: backlinks,
                                onActivateBacklink: onActivateBacklink
                            )
                        }
                    }
                },
                toolbar: {
                    KeyboardToolbarView(
                        suggestion: "An organism is a living system maintaining both a higher level of internal cooperation"
                    )
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isEditorFocused {
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
