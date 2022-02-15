//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailView: View {
    private static func calcTextFieldHeight(
        containerHeight: CGFloat,
        isKeyboardUp: Bool,
        hasBacklinks: Bool
    ) -> CGFloat {
        if !isKeyboardUp && hasBacklinks {
            return UIFont.appTextMono.lineHeight * 8
        } else {
            return containerHeight
        }
    }

    /// If we have a Slug, we're ready to edit.
    /// If we don't, we have nothing to edit.
    var slug: Slug?
    var backlinks: [EntryStub]
    var linkSuggestions: [Suggestion]
    @Binding var focus: AppModel.Focus?
    @Binding var editorDom: Subtext
    @Binding var editorSelection: NSRange
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
    var onCommitLinkSearch: (Slug) -> Void
    var onRename: (Slug?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if slug == nil {
                ProgressScrim()
            } else {
                PseudoKeyboardToolbarView(
                    isKeyboardUp: focus == .editor,
                    toolbarHeight: 48,
                    toolbar: DetailKeyboardToolbarView(
                        onCommit: onCommitLinkSearch,
                        isSheetPresented: $isLinkSheetPresented,
                        suggestions: linkSuggestions
                    ),
                    content: { isKeyboardUp, size in
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                MarkupTextViewRepresenable(
                                    onLink: onEditorLink,
                                    dom: $editorDom,
                                    selection: $editorSelection,
                                    focus: $focus,
                                    field: .editor,
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
                                .frame(
                                    minHeight: Self.calcTextFieldHeight(
                                        containerHeight: size.height,
                                        isKeyboardUp: isKeyboardUp,
                                        hasBacklinks: backlinks.count > 0
                                    )
                                )
                                if !isKeyboardUp && backlinks.count > 0 {
                                    ThickDividerView()
                                        .padding(.bottom, AppTheme.unit4)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DetailToolbarContent(
                focus: focus,
                title: editorDom.title(),
                slug: slug,
                onRename: onRename,
                onDone: onDone
            )
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
