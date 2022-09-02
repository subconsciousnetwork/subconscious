//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI
import os
import ObservableStore
import Combine

enum DetailAction: Hashable {
    case markupEditor(MarkupTextAction<AppFocus>)
    case openEditorURL(URL)
    /// Invokes save and blurs editor
    case selectDoneEditing

    /// Update entry being displayed
    case updateDetail(detail: EntryDetail, autofocus: Bool)

    //  Saving entry
    /// Save an entry at a particular snapshot value
    case save
    case succeedSave(SubtextFile)
    case failSave(
        slug: Slug,
        message: String
    )

    case selectBacklink(EntryLink)
    case requestRename(EntryLink)
    case requestConfirmDelete(Slug)

    // Editor
    /// Update editor dom and mark if this state is saved or not
    case setEditor(text: String, saveState: SaveState)
    /// Set selected range in editor
    case setEditorSelection(NSRange)
    /// Insert text into editor, replacing range
    case insertEditorText(
        text: String,
        range: NSRange
    )

    /// Insert wikilink markup, wrapping range
    case insertEditorWikilinkAtSelection
    case insertEditorBoldAtSelection
    case insertEditorItalicAtSelection
    case insertEditorCodeAtSelection

    /// Refresh after save
    case refreshAll

    static func requestFocus(_ focus: AppFocus?) -> Self {
        .markupEditor(.requestFocus(focus))
    }

    /// Update editor dom and always mark modified
    static func modifyEditor(text: String) -> Self {
        Self.setEditor(text: text, saveState: .modified)
    }
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
        case let .setEditor(text, saveState):
            return setEditor(
                state: state,
                environment: environment,
                text: text,
                saveState: saveState
            )
        case let .setEditorSelection(range):
            return setEditorSelection(
                state: state,
                environment: environment,
                range: range
            )
        case let .insertEditorText(text, range):
            return insertEditorText(
                state: state,
                environment: environment,
                text: text,
                range: range
            )
        case .selectDoneEditing:
            return selectDoneEditing(
                state: state,
                environment: environment
            )
        case 
        case .save:
            return save(
                state: state,
                environment: environment
            )
        case let .succeedSave(entry):
            return succeedSave(
                state: state,
                environment: environment,
                entry: entry
            )
        case let .failSave(slug, message):
            return failSave(
                state: state,
                environment: environment,
                slug: slug,
                message: message
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
        case .insertEditorWikilinkAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Wikilink(text: text) }
            )
        case .insertEditorBoldAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Bold(text: text) }
            )
        case .insertEditorItalicAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Italic(text: text) }
            )
        case .insertEditorCodeAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Code(text: text) }
            )
        case .refreshAll:
            return debug(
                state: state,
                environment: environment,
                message: ".refreshAll should be handled by parent component"
            )
        }
    }

    /// Log debug
    static func debug(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.debug("\(message)")
        return Update(state: state)
    }

    /// Set the contents of the editor.
    ///
    /// if `isSaved` is `false`, the editor state will be flagged as unsaved,
    /// allowing other processes to save it to disk later.
    /// When setting a `dom` that represents the current saved-to-disk state
    /// mark `isSaved` true.
    ///
    /// - Parameters:
    ///   - state: the state of the app
    ///   - dom: the Subtext DOM that should be rendered and set
    ///   - isSaved: is this text state saved already?
    static func setEditor(
        state: DetailModel,
        environment: AppEnvironment,
        text: String,
        saveState: SaveState = .modified
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.editor.text = text
        // Mark save state
        model.editor.saveState = saveState
        let dom = Subtext.parse(markup: text)
        let link = dom.entryLinkFor(range: state.editor.selection)
        model.editor.selectedEntryLinkMarkup = link

        let linkSearchText = link?.toTitle() ?? ""

        return Update(state: model)
            .pipe({ state in
                setLinkSearch(
                    state: state,
                    environment: environment,
                    text: linkSearchText
                )
            })
    }

    /// Set editor selection.
    static func setEditorSelection(
        state: DetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.editor.selection = nsRange
        let dom = Subtext.parse(markup: model.editor.text)
        let link = dom.entryLinkFor(
            range: model.editor.selection
        )
        model.editor.selectedEntryLinkMarkup = link

        let linkSearchText = link?.toTitle() ?? ""

        return Update(state: model)
            .pipe({ state in
                setLinkSearch(
                    state: state,
                    environment: environment,
                    text: linkSearchText
                )
            })
    }

    /// Set text cursor at end of editor
    static func setEditorSelectionEnd(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        let range = NSRange(
            state.editor.text.endIndex...,
            in: state.editor.text
        )

        return setEditorSelection(
            state: state,
            environment: environment,
            range: range
        )
    }

    /// Insert text in editor at range
    static func insertEditorText(
        state: DetailModel,
        environment: AppEnvironment,
        text: String,
        range nsRange: NSRange
    ) -> Update<DetailModel, DetailAction> {
        guard let range = Range(nsRange, in: state.editor.text) else {
            environment.logger.log(
                "Cannot replace text. Invalid range: \(nsRange))"
            )
            return Update(state: state)
        }

        // Replace selected range with committed link search text.
        let markup = state.editor.text.replacingCharacters(
            in: range,
            with: text
        )

        // Find new cursor position
        guard let cursor = markup.index(
            range.lowerBound,
            offsetBy: text.count,
            limitedBy: markup.endIndex
        ) else {
            environment.logger.log(
                "Could not find new cursor position. Aborting text insert."
            )
            return Update(state: state)
        }

        // Set editor dom and editor selection immediately in same
        // Update.
        return setEditor(
            state: state,
            environment: environment,
            text: markup,
            saveState: .modified
        )
        .pipe({ state in
            setEditorSelection(
                state: state,
                environment: environment,
                range: NSRange(cursor..<cursor, in: markup)
            )
        })
    }

    /// Unfocus editor and save current state
    static func selectDoneEditing(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = Just(
            DetailAction.requestFocus(nil)
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
            .pipe({ model in
                save(
                    state: state,
                    environment: environment
                )
            })
    }

    /// Save snapshot of entry
    static func save(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        // If editor dom is already saved, noop
        guard state.editor.saveState != .saved else {
            return Update(state: state)
        }
        var model = state

        // Derive entry from editor
        guard let entry = snapshotEditor(model.editor) else {
            let saveState = String(reflecting: state.editor.saveState)
            environment.logger.warning(
                "Entry save state is marked \(saveState) but no entry could be derived for state. Doing nothing."
            )
            return Update(state: state)
        }

        // Mark saving in-progress
        model.editor.saveState = .saving

        let fx: Fx<DetailAction> = environment.database
            .writeEntryAsync(entry)
            .map({ _ in
                DetailAction.succeedSave(entry)
            })
            .catch({ error in
                Just(
                    DetailAction.failSave(
                        slug: entry.slug,
                        message: error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }

    /// Log save success and perform refresh of various lists.
    static func succeedSave(
        state: DetailModel,
        environment: AppEnvironment,
        entry: SubtextFile
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.debug(
            "Saved entry: \(entry.slug)"
        )
        let fx = Just(DetailAction.refreshAll)
            .eraseToAnyPublisher()

        var model = state

        // If editor state is still the state we invoked save with,
        // then mark the current editor state as "saved".
        // We check before setting in case changes happened between the
        // time we invoked save and the time it completed.
        // If changes did happen in that time, we want to mark the current
        // state modified, giving other processes a chance to save the
        // new changes.
        // 2022-02-09 Gordon Brander
        if
            model.editor.saveState == .saving &&
            model.editor.stateMatches(entry: entry)
        {
            model.editor.saveState = .saved
        }

        return Update(state: model, fx: fx)
    }

    static func failSave(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug,
        message: String
    ) -> Update<DetailModel, DetailAction> {
        //  TODO: show user a "try again" banner
        environment.logger.warning(
            "Save failed for entry (\(slug)) with error: \(message)"
        )
        // Mark modified, since we failed to save
        var model = state
        model.editor.saveState = .modified
        return Update(state: model)
    }

    /// Insert wikilink markup into editor, begining at previous range
    /// and wrapping the contents of previous range
    static func insertTaggedMarkup<T>(
        state: DetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        with withMarkup: (String) -> T
    ) -> Update<DetailModel, DetailAction>
    where T: TaggedMarkup
    {
        guard let range = Range(nsRange, in: state.editor.text) else {
            environment.logger.log(
                "Cannot replace text. Invalid range: \(nsRange))"
            )
            return Update(state: state)
        }

        let selectedText = String(state.editor.text[range])
        let markup = withMarkup(selectedText)

        // Replace selected range with committed link search text.
        let editorText = state.editor.text.replacingCharacters(
            in: range,
            with: String(describing: markup)
        )

        // Find new cursor position
        guard let cursor = editorText.index(
            range.lowerBound,
            offsetBy: markup.markupWithoutClosingTag.count,
            limitedBy: editorText.endIndex
        ) else {
            environment.logger.log(
                "Could not find new cursor position. Aborting text insert."
            )
            return Update(state: state)
        }

        // Set editor dom and editor selection immediately in same
        // Update.
        return setEditor(
            state: state,
            environment: environment,
            text: editorText,
            saveState: .modified
        )
        .pipe({ state in
            setEditorSelection(
                state: state,
                environment: environment,
                range: NSRange(cursor..<cursor, in: editorText)
            )
        })
    }

    /// Snapshot editor state in preparation for saving.
    /// Also mends header files.
    static func snapshotEditor(_ editor: Editor) -> SubtextFile? {
        guard let entry = SubtextFile(editor) else {
            return nil
        }
        return entry.modified(Date.now)
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
                    DetailKeyboardToolbarView(
                        isSheetPresented: store.binding(
                            get: \.isLinkSheetPresented,
                            tag: NotebookAction.setLinkSheetPresented
                        ),
                        selectedEntryLinkMarkup:
                            store.state.editor.selectedEntryLinkMarkup,
                        suggestions: store.state.linkSuggestions,
                        onSelectLinkCompletion: { link in
                            store.send(.selectLinkCompletion(link))
                        },
                        onInsertWikilink: {
                            store.send(.insertEditorWikilinkAtSelection)
                        },
                        onInsertBold: {
                            store.send(.insertEditorBoldAtSelection)
                        },
                        onInsertItalic: {
                            store.send(.insertEditorItalicAtSelection)
                        },
                        onInsertCode: {
                            store.send(.insertEditorCodeAtSelection)
                        },
                        onDoneEditing: {
                            store.send(.selectDoneEditing)
                        }
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
