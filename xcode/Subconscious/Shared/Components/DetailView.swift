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
            return containerHeight - (AppTheme.unit * 24)
        } else {
            return containerHeight
        }
    }

    /// If we have a Slug, we're ready to edit.
    /// If we don't, we have nothing to edit.
    var slug: Slug?
    var backlinks: [EntryStub]
    var linkSuggestions: Suggestions
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
        VStack {
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
            ToolbarItem(placement: .principal) {
                if focus != .editor {
                    Button(
                        action: {
                            onRename(slug)
                        }
                    ) {
                        Text(slug?.description ?? "Untitled")
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
