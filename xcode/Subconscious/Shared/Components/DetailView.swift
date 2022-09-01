//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI
import os
import ObservableStore

enum DetailAction: Hashable {
    case markupEditor(MarkupTextAction<AppFocus>)
    case openEditorURL(URL)
    case selectBacklink(EntryLink)
    case requestRename(EntryLink)
    case requestConfirmDelete(Slug)
}

struct DetailModel: Hashable {
    var focus: AppFocus?
    var editor = Editor()
    var markupEditor = MarkupTextModel<AppFocus>()

    static func update(
        state: DetailModel,
        action: DetailAction,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        switch action {
        case .markupEditor(let action):
            return DetailMarkupEditorCursor.update(
                with: MarkupTextModel.update,
                state: state,
                action: action,
                environment: ()
            )
        case .openEditorURL(_):
            return debug(
                state: state,
                environment: environment,
                message: "openEditorURL should be handled by parent component"
            )
        case .selectBacklink(_):
            return debug(
                state: state,
                environment: environment,
                message: "selectBacklink should be handled by parent component"
            )
        case .requestRename(_):
            return debug(
                state: state,
                environment: environment,
                message: "selectBacklink should be handled by parent component"
            )
        case .requestConfirmDelete(_):
            return debug(
                state: state,
                environment: environment,
                message: "requestConfirmDelete should be handled by parent component"
            )
        }
    }

    static func debug(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.debug("\(message)")
        return Update(state: state)
    }
}

/// Editor cursor
struct DetailMarkupEditorCursor: CursorProtocol {
    typealias OuterState = DetailModel
    typealias InnerState = MarkupTextModel<AppFocus>
    typealias OuterAction = DetailAction
    typealias InnerAction = MarkupTextAction<AppFocus>

    static func get(state: OuterState) -> InnerState {
        state.markupEditor
    }

    static func set(state: OuterState, inner: InnerState) -> OuterState {
        var model = state
        model.markupEditor = inner
        return model
    }
    
    static func tag(action: InnerAction) -> OuterAction {
        .markupEditor(action)
    }
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
                            MarkupTextViewRepresentable2(
                                store: store.viewStore(
                                    get: DetailMarkupEditorCursor.get,
                                    tag: DetailMarkupEditorCursor.tag
                                ),
                                field: .editor,
                                frame: geometry.frame(in: .local),
                                renderAttributesOf: Subtext.renderAttributesOf,
                                onLink: { url, _, _, _ in
                                    store.send(.openEditorURL(url))
                                    return false
                                },
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
