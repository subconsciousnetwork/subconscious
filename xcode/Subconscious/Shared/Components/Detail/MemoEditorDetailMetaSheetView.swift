//
//  MemoEditorDetailMetaSheetView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI
import ObservableStore
import Combine

struct MemoEditorDetailMetaSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
                    let colors = NoteColor.allCases
                    
                    ForEach(colors, id: \.self) { color in
                        Button(
                            action: {
                                store.send(.requestAssignNoteColor(color))
                            }
                        ) {
                            ZStack {
                                Circle()
                                    .fill(color.toColor(colorScheme: colorScheme))
                                Circle()
                                    .stroke(Color.separator)
                                if color == store.state.defaultColor {
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
    }
}

enum MemoEditorDetailMetaSheetAction: Hashable {
    /// Tagged actions for rename search sheet
    case renameSearch(RenameSearchAction)
    case presentRenameSheet(_ isPresented: Bool)
    case presentRenameSheetFor(_ address: Slashlink?)
    case selectRenameSuggestion(RenameSuggestion)
    case setAddress(_ address: Slashlink?)
    case setDefaultAudience(_ audience: Audience)
    
    /// Requests that audience be updated.
    /// Should be handled by parent component.
    case requestUpdateAudience(_ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
    
    case setDefaultNoteColor(_ color: NoteColor?)
    case requestAssignNoteColor(_ color: NoteColor?)
    case failAssignNoteColor
    case succeedAssignNoteColor
    
    //  Delete entry requests
    /// Show/hide delete confirmation dialog
    case presentDeleteConfirmationDialog(Bool)
    /// Request this address be deleted.
    /// Should be handled by parent component.
    case requestDelete(Slashlink?)

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
    var defaultColor: NoteColor?
    var defaultAudience = Audience.local
    var audience: Audience {
        address?.toAudience() ?? defaultAudience
    }
    var isRenameSheetPresented = false
    var renameSearch = RenameSearchModel()
    
    /// Is delete confirmation dialog presented?
    var isDeleteConfirmationDialogPresented = false
    
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
        case let .setAddress(address):
            return setAddress(
                state: state,
                environment: environment,
                address: address
            )
        case .setDefaultAudience(let audience):
            return setDefaultAudience(
                state: state,
                environment: environment,
                audience: audience
            )
        case .requestUpdateAudience:
            return Update(state: state)
        case .succeedUpdateAudience(let receipt):
            return update(
                state: state,
                action: .setAddress(receipt.to),
                environment: environment
            )
        case .requestDelete:
            return Update(state: state)
        case let .setDefaultNoteColor(color):
            return setDefaultNoteColor(
                state: state,
                environment: environment,
                color: color
            )
        case .requestAssignNoteColor(let color):
            return requestAssignNoteColor(state: state, environment: environment, color: color)
        case .failAssignNoteColor:
            return Update(state: state)
        case .succeedAssignNoteColor:
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
    
    static func setDefaultAudience(
        state: Self,
        environment: Environment,
        audience: Audience
    ) -> Update<Self> {
        var model = state
        model.defaultAudience = audience
        return Update(state: model)
    }
    
    static func setDefaultNoteColor(
        state: Self,
        environment: Environment,
        color: NoteColor?
    ) -> Update<Self> {
        var model = state
        model.defaultColor = color
        
        return Update(state: model)
    }
    
    static func requestAssignNoteColor(
        state: Self,
        environment: Environment,
        color: NoteColor?
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            guard let address = state.address,
                  let color = color else {
                return .failAssignNoteColor
            }
            
            try await environment.data.assignNoteColor(
                address: address,
                color: color
            )
            
            return .succeedAssignNoteColor
        }
        .recover { error in
            return .failAssignNoteColor
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
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
