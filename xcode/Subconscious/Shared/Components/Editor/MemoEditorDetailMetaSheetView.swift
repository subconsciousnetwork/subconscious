//
//  MemoEditorDetailMetaSheetView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI
import ObservableStore

struct MemoEditorDetailMetaSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var store: ViewStore<MemoEditorDetailMetaSheetModel>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    HStack {
                        if let slashlink = store.state.address {
                            SlashlinkDisplayView(slashlink: slashlink).theme(
                                base: Color.primary,
                                slug: Color.secondary
                            )
                        } else {
                            Text("Draft")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.callout)
                    AudienceMenuButtonView(
                        audience: store.binding(
                            get: \.audience,
                            tag: MemoEditorDetailMetaSheetAction.requestUpdateAudience
                        )
                    )
                }
                Spacer()
                CloseButtonView(action: { dismiss() })
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading) {
                    MetaTableView {
                        Button(
                            action: {
                                store.send(.presentRenameSheetFor(store.state.address))
                            }
                        ) {
                            Label(
                                "Edit link",
                                systemImage: "link"
                            )
                        }
                        .buttonStyle(RowButtonStyle())
                        
                        Divider()
                        
                        if let address = store.state.address {
                            if store.state.liked {
                                Button(
                                    action: {
                                        store.send(.requestUpdateLikeStatus(address, liked: false))
                                    },
                                    label: {
                                        Label(
                                            "Unlike",
                                            systemImage: "heart.slash"
                                        )
                                    }
                                )
                                .buttonStyle(RowButtonStyle())
                            } else {
                                Button(
                                    action: {
                                        store.send(.requestUpdateLikeStatus(address, liked: true))
                                    },
                                    label: {
                                        Label(
                                            "Like",
                                            systemImage: "heart"
                                        )
                                    }
                                )
                                .buttonStyle(RowButtonStyle())
                            }
                            
                            Divider()
                            
                            Button(
                                action: {
                                    store.send(.requestQuoteInNewNote(address))
                                },
                                label: {
                                    Label(
                                        "Quote",
                                        systemImage: "quote.opening"
                                    )
                                }
                            )
                            .buttonStyle(RowButtonStyle())
                            
                            Divider()
                        }
                        
                        Button(
                            action: {
                                store.send(.presentAppendLinkSearchSheet(true))
                            },
                            label: {
                                Label(
                                    "Append to note",
                                    systemImage: "link.badge.plus"
                                )
                            }
                        )
                        .buttonStyle(RowButtonStyle())
                        
                        Divider()
                        
                        Button(
                            role: .destructive,
                            action: {
                                store.send(.presentDeleteConfirmationDialog(true))
                            }
                        ) {
                            Label(
                                "Delete",
                                systemImage: "trash"
                            )
                        }
                        .buttonStyle(RowButtonStyle())
                        Divider()
                    }
                }
                .padding()
                
                HStack(spacing: AppTheme.padding) {
                    let themeColors = ThemeColor.allCases
                    
                    ForEach(themeColors, id: \.self) { themeColor in
                        Button(
                            action: {
                                store.send(.requestAssignNoteColor(themeColor))
                            }
                        ) {
                            ZStack {
                                Circle()
                                    .fill(themeColor.toColor())
                                Circle()
                                    .stroke(Color.separator)
                                if themeColor == store.state.themeColor {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 32, height: 32)
                        }
                    }
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
        .sheet(
            isPresented: store.binding(
                get: \.isRenameSheetPresented,
                tag: MemoEditorDetailMetaSheetAction.presentRenameSheet
            )
        ) {
            RenameSearchView(
                store: store.viewStore(
                    get: \.renameSearch,
                    tag: MemoEditorDetailMetaSheetRenameSearchCursor.tag
                )
            )
        }
        .confirmationDialog(
            "Are you sure you want to delete this note?",
            isPresented: store.binding(
                get: \.isDeleteConfirmationDialogPresented,
                tag: MemoEditorDetailMetaSheetAction.presentDeleteConfirmationDialog
            ),
            titleVisibility: .visible
        ) {
            Button(
                role: .destructive,
                action: {
                    store.send(.requestDelete(store.state.address))
                }
            ) {
                Text("Delete")
            }
        }
        .sheet(
            isPresented: store.binding(
                get: \.isAppendLinkSearchPresented,
                tag: MemoEditorDetailMetaSheetAction.presentAppendLinkSearchSheet
            )
        ) {
            AppendLinkSearchView(
                store: store.viewStore(
                    get: \.appendLinkSearch,
                    tag: MemoEditorDetailMetaSheetAppendLinkSearchCursor.tag
                )
            )
        }
    }
}

enum MemoEditorDetailMetaSheetAction: Hashable {
    /// Tagged actions for rename search sheet
    case renameSearch(RenameSearchAction)
    case presentRenameSheet(_ isPresented: Bool)
    case presentRenameSheetFor(_ address: Slashlink?)
    case selectRenameSuggestion(RenameSuggestion)
    case setAddress(_ address: Slashlink?)
    case setLiked(_ liked: Bool)
    case setDefaultAudience(_ audience: Audience)
    
    /// Requests that audience be updated.
    /// Should be handled by parent component.
    case requestUpdateAudience(_ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
    
    case setNoteColor(_ color: ThemeColor?)
    case requestAssignNoteColor(_ color: ThemeColor)
    case succeedAssignNoteColor(_ color: ThemeColor)
    
    case requestUpdateLikeStatus(_ address: Slashlink, liked: Bool)
    case succeedUpdateLikeStatus(_ address: Slashlink, liked: Bool)
    
    //  Delete entry requests
    /// Show/hide delete confirmation dialog
    case presentDeleteConfirmationDialog(Bool)
    /// Request this address be deleted.
    /// Should be handled by parent component.
    case requestDelete(Slashlink?)
    case requestQuoteInNewNote(_ address: Slashlink, comment: String? = nil)
    
    /// Tagged actions for append link search sheet
    case appendLinkSearch(AppendLinkSearchAction)
    case presentAppendLinkSearchSheet(_ isPresented: Bool)
    case selectAppendLinkSearchSuggestion(AppendLinkSuggestion)
    
    static func setAppendLinkSearchSubject(_ address: Slashlink?) -> Self {
        .appendLinkSearch(.setSubject(address))
    }

    static var refreshRenameSuggestions: Self {
        .renameSearch(.refreshRenameSuggestions)
    }
    
    static func setRenameSearchSubject(_ address: Slashlink?) -> Self {
        .renameSearch(.setSubject(address))
    }
}

struct MemoEditorDetailMetaSheetModel: ModelProtocol {
    typealias Action = MemoEditorDetailMetaSheetAction
    typealias Environment = AppEnvironment
    
    var address: Slashlink?
    var themeColor: ThemeColor?
    var defaultAudience = Audience.local
    var audience: Audience {
        address?.toAudience() ?? defaultAudience
    }
    var isRenameSheetPresented = false
    var renameSearch = RenameSearchModel()
    var liked = false
    
    /// Is delete confirmation dialog presented?
    var isDeleteConfirmationDialogPresented = false
    
    var isAppendLinkSearchPresented = false
    var appendLinkSearch = AppendLinkSearchModel()
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> ObservableStore.Update<Self> {
        switch action {
        case .renameSearch(let action):
            return MemoEditorDetailMetaSheetRenameSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .presentRenameSheet(let isPresented):
            return presentRenameSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .presentRenameSheetFor(let address):
            return update(
                state: state,
                actions: [
                    .setRenameSearchSubject(address),
                    .presentRenameSheet(true)
                ],
                environment: environment
            )
        case .selectRenameSuggestion(let suggestion):
            return selectRenameSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        case .presentDeleteConfirmationDialog(let isPresented):
            return presentDeleteConfirmationDialog(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        // Append link
        case .appendLinkSearch(let action):
            return MemoEditorDetailMetaSheetAppendLinkSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .presentAppendLinkSearchSheet(let isPresented):
            return presentAppendLinkSearchSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .selectAppendLinkSearchSuggestion(let suggestion):
            return selectAppendLinkSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        case let .setAddress(address):
            return setAddress(
                state: state,
                environment: environment,
                address: address
            )
        case let .setLiked(liked):
            return setLiked(
                state: state,
                environment: environment,
                liked: liked
            )
        case .setDefaultAudience(let audience):
            return setDefaultAudience(
                state: state,
                environment: environment,
                audience: audience
            )
        case .succeedUpdateAudience(let receipt):
            return update(
                state: state,
                action: .setAddress(receipt.to),
                environment: environment
            )
        // Editor passes us the current color when the sheet is opened
        case let .setNoteColor(color):
            return setNoteColor(
                state: state,
                environment: environment,
                color: color
            )
        // Update internal color to match the updated value
        case let .succeedAssignNoteColor(color):
            return setNoteColor(
                state: state,
                environment: environment,
                color: color
            )
        case let .succeedUpdateLikeStatus(_, liked):
            return setLiked(
                state: state,
                environment: environment,
                liked: liked
            )
        case .requestUpdateAudience, .requestDelete, .requestAssignNoteColor,
                .requestQuoteInNewNote, .requestUpdateLikeStatus:
            return Update(state: state)
        }
    }
    
    static func presentRenameSheet(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isRenameSheetPresented = isPresented
        return Update(state: model)
    }
    
    static func selectRenameSuggestion(
        state: Self,
        environment: Environment,
        suggestion: RenameSuggestion
    ) -> Update<Self> {
        var model = state
        model.isRenameSheetPresented = false
        return update(
            state: model,
            action: .renameSearch(.selectRenameSuggestion(suggestion)),
            environment: environment
        )
    }
    
    /// Show/hide entry delete confirmation dialog.
    static func presentDeleteConfirmationDialog(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isDeleteConfirmationDialogPresented = isPresented
        return Update(state: model).animation(.default)
    }
    
    static func setAddress(
        state: Self,
        environment: Environment,
        address: Slashlink?
    ) -> Update<Self> {
        var model = state
        model.address = address
        if let address = address {
            model.defaultAudience = address.toAudience()
        }
        return update(
            state: model,
            action: .renameSearch(.setSubject(address)),
            environment: environment
        )
    }
    
    static func setLiked(
        state: Self,
        environment: Environment,
        liked: Bool
    ) -> Update<Self> {
        var model = state
        model.liked = liked
        return Update(state: model)
    }
    
    static func setDefaultAudience(
        state: Self,
        environment: Environment,
        audience: Audience
    ) -> Update<Self> {
        var model = state
        model.defaultAudience = audience
        return Update(state: model)
    }
    
    static func setNoteColor(
        state: Self,
        environment: Environment,
        color: ThemeColor?
    ) -> Update<Self> {
        var model = state
        model.themeColor = color
        
        return Update(state: model)
    }
    
    static func presentAppendLinkSearchSheet(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        guard let address = state.address else {
            return Update(state: state)
        }
        
        var model = state
        model.isAppendLinkSearchPresented = isPresented
        return update(
            state: model,
            action: .setAppendLinkSearchSubject(address),
            environment: environment
        )
    }
    
    static func selectAppendLinkSuggestion(
        state: Self,
        environment: Environment,
        suggestion: AppendLinkSuggestion
    ) -> Update<Self> {
        var model = state
        model.isAppendLinkSearchPresented = false
        return update(
            state: model,
            actions: [
                .appendLinkSearch(.selectSuggestion(suggestion)),
                .presentAppendLinkSearchSheet(false)
            ],
            environment: environment
        )
    }
}

// MARK: RenameSearchCursor
struct MemoEditorDetailMetaSheetRenameSearchCursor: CursorProtocol {
    typealias Model = MemoEditorDetailMetaSheetModel
    typealias ViewModel = RenameSearchModel

    static func get(state: Model) -> ViewModel {
        state.renameSearch
    }
    
    static func set(
        state: Model,
        inner: ViewModel
    ) -> Model {
        var model = state
        model.renameSearch = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .selectRenameSuggestion(let suggestion):
            return .selectRenameSuggestion(suggestion)
        default:
            return .renameSearch(action)
        }
    }
}

// MARK: AppendLinkSearchCursor
struct MemoEditorDetailMetaSheetAppendLinkSearchCursor: CursorProtocol {
    typealias Model = MemoEditorDetailMetaSheetModel
    typealias ViewModel = AppendLinkSearchModel

    static func get(state: Model) -> ViewModel {
        state.appendLinkSearch
    }
    
    static func set(
        state: Model,
        inner: ViewModel
    ) -> Model {
        var model = state
        model.appendLinkSearch = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .selectSuggestion(let suggestion):
            return .selectAppendLinkSearchSuggestion(suggestion)
        default:
            return .appendLinkSearch(action)
        }
    }
}

struct MemoEditorDetailActionBottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
        }
        .sheet(isPresented: .constant(true)) {
            MemoEditorDetailMetaSheetView(
                store: Store(
                    state: MemoEditorDetailMetaSheetModel(
                        address: Slashlink.local(
                            Slug("the-whale-the-whale")!
                        )
                    ),
                    environment: MemoEditorDetailMetaSheetModel.Environment()
                ).toViewStoreForSwiftUIPreview()
            )
        }
    }
}
