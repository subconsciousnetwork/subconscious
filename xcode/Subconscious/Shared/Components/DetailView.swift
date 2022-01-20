//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailView: View {
    /// If we have a Slug, we're ready to edit.
    /// If we don't, we have nothing to edit.
    var slug: Slug?
    var backlinks: [EntryStub]
    var linkSuggestions: [Suggestion]
    @Binding var focus: AppModel.Focus?
    @Binding var editorAttributedText: NSAttributedString
    @Binding var editorSelection: NSRange
    @Binding var isRenamePresented: Bool
    @Binding var isLinkSheetPresented: Bool
    @Binding var linkSearchText: String
    var onDone: () -> Void
    var onEditorLink: (
        URL,
        NSAttributedString,
        NSRange,
        UITextItemInteraction
    ) -> Bool
    var onCommitSearch: (String) -> Void
    var onCommitLinkSearch: (String) -> Void

    var body: some View {
        VStack {
            if slug == nil {
                ProgressScrim()
            } else {
                GeometryReader { geometry in
                    PseudoKeyboardToolbarView(
                        isKeyboardUp: focus == .editor,
                        toolbarHeight: 48,
                        toolbar: KeyboardToolbarView(
                            isSheetPresented: $isLinkSheetPresented,
                            suggestions: .constant([])
                        ),
                        content: { isKeyboardUp, size in
                            ScrollView(.vertical) {
                                VStack(spacing: 0) {
                                    GrowableAttributedTextViewRepresentable(
                                        attributedText: $editorAttributedText,
                                        selection: $editorSelection,
                                        focus: $focus,
                                        field: .editor,
                                        onLink: onEditorLink,
                                        fixedWidth: size.width
                                    )
                                    .insets(
                                        EdgeInsets(
                                            top: AppTheme.margin,
                                            leading: AppTheme.margin,
                                            bottom: AppTheme.margin,
                                            trailing: AppTheme.margin
                                        )
                                    )
                                    .frame(
                                        minHeight: size.height
                                    )
                                    if !isKeyboardUp && backlinks.count > 0 {
                                        Divider()
                                        BacklinksView(
                                            backlinks: backlinks,
                                            onActivateBacklink: onCommitSearch
                                        )
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if focus != .editor {
                    Button(
                        action: {
                            self.isRenamePresented = true
                        }
                    ) {
                        Text(slug ?? "Untitled")
                    }
                    .buttonStyle(MicroFieldButtonStyle())
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if focus == .editor {
                    HStack {
                        Button(
                            action: onDone
                        ) {
                            Text("Done").bold()
                        }
                        .foregroundColor(.buttonText)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .transition(.opacity)
                    }
                    .opacity(focus == .editor ? 1 : 0)
                } else {
                    HStack{
                        EmptyView()
                    }
                    .frame(width: 24, height: 24)
                }
            }
        }
        .sheet(
            isPresented: $isLinkSheetPresented,
            onDismiss: {}
        ) {
            LinkSearchView(
                placeholder: "Search or create...",
                suggestions: linkSuggestions,
                text: $linkSearchText,
                focus: $focus,
                onCancel: {
                    isLinkSheetPresented = false
                },
                onCommit: { slug in
                    onCommitLinkSearch(slug)
                }
            )
        }
    }
}
