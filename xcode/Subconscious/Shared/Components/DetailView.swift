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

    private var isKeyboardUp: Bool {
        focus == .editor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Divider()
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            MarkupTextViewRepresenable(
                                dom: $editorDom,
                                selection: $editorSelection,
                                focus: $focus,
                                field: .editor,
                                fixedWidth: geometry.size.width,
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
                    if isKeyboardUp {
                        DetailKeyboardToolbarView(
                            isSheetPresented: $isLinkSheetPresented,
                            suggestions: linkSuggestions,
                            onSelect: onSelectLink
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
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )
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
                BottomSheetView(
                    isPresented: $isLinkSheetPresented,
                    height: geometry.size.height,
                    containerSize: geometry.size,
                    content: LinkSearchView(
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
                    .frame(height: geometry.size.height)
                )
                .zIndex(3)
            }
        }
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
    }
}
