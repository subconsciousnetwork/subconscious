//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailView: View {
    /// Access dismiss function from environment. This lets us drive the custom
    /// back button behavior.
    /// See https://developer.apple.com/documentation/swiftui/dismissaction.
    /// 2022-01-12 Gordon Brander
    @Environment(\.dismiss) var dismiss
    /// Track gesture state.
    //  NOTE: It's unclear if we can easily integrate this with app state.
    //  For now, we'll stick to the happy path of keeping it internal
    //  to the view.
    //  2022-01-12 Gordon Brander
    //  TODO: figure out how to bring back swipe animation
    //  2022-01-12 Gordon Brander
    @GestureState private var dismissDragOffset = CGSize.zero
    /// If we have an entryURL, we're ready to edit.
    /// If we don't, we have nothing to edit.
    var entryURL: URL?
    var backlinks: [EntryStub]
    @Binding var focus: AppModel.Focus?
    @Binding var editorAttributedText: NSAttributedString
    @Binding var editorSelection: NSRange
    @Binding var isLinkSheetPresented: Bool
    @Binding var linkSearchText: String
    @Binding var linkSuggestions: [Suggestion]
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
            if entryURL == nil {
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
        .gesture(
            DragGesture(minimumDistance: 100)
                .updating(
                    $dismissDragOffset
                ) { current, gesture, transaction in
                    if focus != .editor && current.startLocation.x < 20 {
                        dismiss()
                    }
                }
        )
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if focus != .editor {
                    Button(
                        action: {
                            dismiss()
                        }
                    ) {
                        Label("Ideas", systemImage: "chevron.backward")
                            .labelStyle(BackLabelStyle())
                    }
                    .transition(.opacity)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if focus == .editor {
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
            }
        }
        .sheet(
            isPresented: $isLinkSheetPresented,
            onDismiss: {}
        ) {
            LinkSearchView(
                placeholder: "Search or create...",
                text: $linkSearchText,
                focus: $focus,
                suggestions: $linkSuggestions,
                onCancel: {
                    isLinkSheetPresented = false
                },
                onCommitLinkSearch: { slug in
                    onCommitLinkSearch(slug)
                }
            )
        }
    }
}
