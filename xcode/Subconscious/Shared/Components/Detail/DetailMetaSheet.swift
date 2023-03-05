//
//  DetailMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI
import ObservableStore

struct DetailMetaSheet: View {
    @Environment(\.dismiss) private var dismiss
    var state: DetailMetaSheetModel
    var send: (DetailMetaSheetAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    SlashlinkBylineView(
                        slashlink: state.address?.toSlashlink(),
                        fallback: String(localized: "Draft")
                    )
                    .theme(
                        petname: Color.primary,
                        slug: Color.secondary
                    )
                    .font(.callout)
                    AudienceMenuButtonView(
                        audience: .constant(Audience.public)
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
                                send(.presentRenameSheetFor(state.address))
                            }
                        ) {
                            Label(
                                "Move",
                                systemImage: "folder"
                            )
                        }
                        .buttonStyle(RowButtonStyle())
                        Divider()
                        Button(
                            role: .destructive,
                            action: {
                                send(.presentDeleteConfirmationDialog(true))
                            }
                        ) {
                            Label(
                                "Delete",
                                systemImage: "trash"
                            )
                        }
                        .buttonStyle(RowButtonStyle())
                    }
                }
                .padding()
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
        .sheet(
            isPresented: Binding(
                get: { state.isRenameSheetPresented },
                send: send,
                tag: DetailMetaSheetAction.presentRenameSheet
            )
        ) {
            RenameSearchView(
                state: state.renameSearch,
                send: Address.forward(
                    send: send,
                    tag: DetailMetaSheetRenameSearchCursor.tag
                )
            )
        }
        .confirmationDialog(
            "Are you sure you want to delete?",
            isPresented: Binding(
                get: { state.isDeleteConfirmationDialogPresented },
                send: send,
                tag: DetailMetaSheetAction.presentDeleteConfirmationDialog
            ),
            titleVisibility: .visible
        ) {
            Button(
                role: .destructive,
                action: {
                    send(.requestDelete(state.address))
                }
            ) {
                Text("Delete")
            }
        }
    }
}

enum DetailMetaSheetAction: Hashable {
    /// Tagged actions for rename search sheet
    case renameSearch(RenameSearchAction)
    case presentRenameSheet(_ isPresented: Bool)
    case presentRenameSheetFor(_ address: MemoAddress?)
    case selectRenameSuggestion(RenameSuggestion)
    case setAddress(_ address: MemoAddress?)
    
    //  Delete entry requests
    /// Show/hide delete confirmation dialog
    case presentDeleteConfirmationDialog(Bool)
    case requestDelete(MemoAddress?)

    static var refreshRenameSuggestions: Self {
        .renameSearch(.refreshRenameSuggestions)
    }
    
    static func setRenameSearchSubject(_ address: MemoAddress?) -> Self {
        .renameSearch(.setSubject(address))
    }
}

struct DetailMetaSheetModel: ModelProtocol {
    typealias Action = DetailMetaSheetAction
    typealias Environment = AppEnvironment
    
    var address: MemoAddress?
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
            return DetailMetaSheetRenameSearchCursor.update(
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
        case .requestDelete:
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
        address: MemoAddress?
    ) -> Update<Self> {
        var model = state
        model.address = address
        return update(
            state: model,
            action: .renameSearch(.setSubject(address)),
            environment: environment
        )
    }
}

//  MARK: RenameSearchCursor
struct DetailMetaSheetRenameSearchCursor: CursorProtocol {
    typealias Model = DetailMetaSheetModel
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

struct DetailActionBottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
        }
        .sheet(isPresented: .constant(true)) {
            DetailMetaSheet(
                state: DetailMetaSheetModel(
                    address: MemoAddress.local(Slug("the-whale-the-whale")!)
                ),
                send: { action in }
            )
        }
    }
}
