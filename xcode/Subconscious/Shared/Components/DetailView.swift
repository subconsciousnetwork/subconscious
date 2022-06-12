//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI
import os

struct DetailModel: Equatable {
    var focus: AppModel.Focus?
    var editor: Editor
}

enum DetailAction {
    case setFocus(AppModel.Focus?)
    case setEditorText(String)
    case setEditorSelection(NSRange)
    case selectBacklink(EntryLink)
    case requestRename(EntryLink)
    case requestConfirmDelete(Slug)
}

struct DetailView: View {
    private static func calcTextFieldHeight(
        containerHeight: CGFloat,
        isKeyboardUp: Bool,
        hasBacklinks: Bool
    ) -> CGFloat {
        UIFont.appTextMono.lineHeight * 8
    }

    var store: ViewStore<DetailModel, DetailAction>
    var linkSuggestions: [LinkSuggestion]
    @Binding var isLinkSheetPresented: Bool
    @Binding var linkSearchText: String
    var onEditorLink: (
        URL,
        NSAttributedString,
        NSRange,
        UITextItemInteraction
    ) -> Bool
    var keyboardToolbar: DetailKeyboardToolbarView

    private var isKeyboardUp: Bool {
        store.state.focus == .editor
    }

    var isReady: Bool {
        let state = store.state
        return !state.editor.isLoading && state.editor.entryInfo?.slug != nil
    }

    private var backlinks: [EntryStub] {
        guard let backlinks = store.state.editor.entryInfo?.backlinks else {
            return []
        }
        return backlinks
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Divider()
                GeometryReader { geometry in
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            MarkupTextViewRepresentable(
                                text: store.binding(
                                    get: \.editor.text,
                                    tag: { text in
                                        .setEditorText(text)
                                    }
                                ),
                                selection: store.binding(
                                    get: { model in model.editor.selection },
                                    tag: { selection in
                                        .setEditorSelection(selection)
                                    }
                                ),
                                focus: store.binding(
                                    get: { model in model.focus },
                                    tag: { focus in .setFocus(focus) }
                                ),
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
                            ThickDividerView()
                                .padding(.bottom, AppTheme.unit4)
                            BacklinksView(
                                backlinks: backlinks,
                                onSelect: { link in
                                    store.send(.selectBacklink(link))
                                }
                            )
                        }
                    }
                }
                if isKeyboardUp {
                    keyboardToolbar.transition(
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
            if !isReady {
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
                link: store.state.editor.entryInfo.map({ info in
                    EntryLink(info)
                }),
                onRename: {
                    if let info = store.state.editor.entryInfo {
                        store.send(.requestRename(EntryLink(info)))
                    }
                },
                onDelete: {
                    if let slug = store.state.editor.entryInfo?.slug {
                        store.send(.requestConfirmDelete(slug))
                    }
                }
            )
        }
    }
}
