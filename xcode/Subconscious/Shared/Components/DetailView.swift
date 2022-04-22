//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI
import os

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
    var selectedEntryLinkMarkup: Subtext.EntryLinkMarkup?
    @Binding var focus: AppModel.Focus?
    @Binding var editorText: String
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
    var onSelectLinkCompletion: (EntryLink) -> Void
    var onInsertWikilink: () -> Void
    var onInsertBold: () -> Void
    var onInsertItalic: () -> Void
    var onInsertCode: () -> Void
    var onRename: (Slug?) -> Void
    var onDelete: (Slug?) -> Void

    private var isKeyboardUp: Bool {
        focus == .editor
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Divider()
                GeometryReader { geometry in
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            MarkupTextViewRepresentable(
                                text: $editorText,
                                selection: $editorSelection,
                                focus: $focus,
                                field: .editor,
                                frame: geometry.frame(in: .local),
                                renderAttributesOf: Subtext.renderAttributesOf,
                                onLink: onEditorLink,
                                logger: Logger.editor
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
                                    containerHeight: geometry.size.height,
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
                if isKeyboardUp {
                    DetailKeyboardToolbarView(
                        isSheetPresented: $isLinkSheetPresented,
                        selectedEntryLinkMarkup: selectedEntryLinkMarkup,
                        suggestions: linkSuggestions,
                        onSelectLinkCompletion: onSelectLinkCompletion,
                        onInsertWikilink: onInsertWikilink,
                        onInsertBold: onInsertBold,
                        onInsertItalic: onInsertItalic,
                        onInsertCode: onInsertCode,
                        onDoneEditing: onDone
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(
                                .easeOutCubic(duration: Duration.normal)
                                .delay(Duration.keyboard)
                            ),
                            removal: .opacity.animation(
                                .easeOutCubic(duration: Duration.normal)
                            )
                        )
                    )
                }
            }
            .zIndex(1)
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
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DetailToolbarContent(
                isEditing: isKeyboardUp,
                title: Subtext(markup: editorText).title(),
                slug: slug,
                onRename: onRename,
                onDelete: onDelete
            )
        }
    }
}
