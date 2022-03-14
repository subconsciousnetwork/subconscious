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
    var isLoading: Bool
    var backlinks: [EntryStub]
    var linkSuggestions: [LinkSuggestion]
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
    var onSelectBacklink: (EntryLink) -> Void
    var onSelectLink: (LinkSuggestion) -> Void
    var onRename: (Slug?) -> Void
    var onDelete: (Slug?) -> Void

    var body: some View {
        ZStack {
            if isLoading || slug == nil {
                Color.background
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.none),
                            removal: .opacity.animation(.default)
                        )
                    )
                    .zIndex(2)
            }
            VStack(spacing: 0) {
                Divider()
                PseudoKeyboardToolbarView(
                    isKeyboardUp: focus == .editor,
                    toolbarHeight: 48,
                    toolbar: DetailKeyboardToolbarView(
                        isSheetPresented: $isLinkSheetPresented,
                        suggestions: linkSuggestions,
                        onSelect: onSelectLink
                    ),
                    content: { isKeyboardUp, size in
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                MarkupTextViewRepresenable(
                                    dom: $editorDom,
                                    selection: $editorSelection,
                                    focus: $focus,
                                    field: .editor,
                                    fixedWidth: size.width,
                                    onLink: onEditorLink
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
                                        onSelect: onSelectBacklink
                                    )
                                }
                            }
                        }
                    }
                )
            }
            .zIndex(1)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DetailToolbarContent(
                    isEditing: (focus == .editor),
                    title: editorDom.title(),
                    slug: slug,
                    onRename: onRename,
                    onDelete: onDelete,
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
                    onSelect: { suggestion in
                        onSelectLink(suggestion)
                    }
                )
        }
        }
    }
}
