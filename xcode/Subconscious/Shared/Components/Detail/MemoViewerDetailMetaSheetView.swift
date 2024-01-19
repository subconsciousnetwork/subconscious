//
//  MemoViewerDetailMetaSheetView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/6/23.
//

import SwiftUI
import Combine
import os
import ObservableStore

struct MemoViewerDetailMetaSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var store: ViewStore<MemoViewerDetailMetaSheetModel>
    
    var body: some View {
        VStack(spacing: 0) {
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
                }
                Spacer()
                CloseButtonView(action: { dismiss() })
            }
            .padding()
            Divider()
            ScrollView {
                VStack(spacing: AppTheme.unit4) {
                    MetaTableView {
                        MetaTableItemShareLinkView(
                            label: "Share link",
                            item: store.state.shareableLink ?? ""
                        )
                        .disabled(store.state.shareableLink == nil)
                        
                        Divider()
                        
                        if let address = store.state.address {
                            Button(
                                action: {
                                    store.send(.requestQuoteInNewNote(address))
                                },
                                label: {
                                    Label(
                                        "Quote in new note",
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
                        
                        if let author = store.state.author {
                            Button(
                                action: {
                                    store.send(.requestAuthorDetail(author))
                                },
                                label: {
                                    Label(
                                        "View Author Profile",
                                        systemImage: "person"
                                    )
                                }
                            )
                            .buttonStyle(RowButtonStyle())
                        }
                    }
                }
                .padding()
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
        .sheet(
            isPresented: store.binding(
                get: \.isAppendLinkSearchPresented,
                tag: MemoViewerDetailMetaSheetAction.presentAppendLinkSearchSheet
            )
        ) {
            AppendLinkSearchView(
                store: store.viewStore(
                    get: \.appendLinkSearch,
                    tag: MemoViewerDetailMetaSheetAppendLinkSearchCursor.tag
                )
            )
        }
    }
}

enum MemoViewerDetailMetaSheetAction: Hashable {
    case setAddress(_ address: Slashlink)
    case setAuthor(_ author: UserProfile)
    case requestDismiss
    case requestAuthorDetail(_ author: UserProfile)
    case requestQuoteInNewNote(_ address: Slashlink)
    
    /// Tagged actions for rename search sheet
    case appendLinkSearch(AppendLinkSearchAction)
    case presentAppendLinkSearchSheet(_ isPresented: Bool)
    case presentAppendLinkSearchSheetFor(_ address: Slashlink?)
    case selectAppendLinkSearchSuggestion(RenameSuggestion)
    
    static func setRenameSearchSubject(_ address: Slashlink?) -> Self {
        .appendLinkSearch(.setSubject(address))
    }
}

// MARK: RenameSearchCursor
struct MemoViewerDetailMetaSheetAppendLinkSearchCursor: CursorProtocol {
    typealias Model = MemoViewerDetailMetaSheetModel
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


struct MemoViewerDetailMetaSheetModel: ModelProtocol {
    typealias Action = MemoViewerDetailMetaSheetAction
    typealias Environment = AppEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetailMetaSheet"
    )
    
    var author: UserProfile?
    var address: Slashlink?
    var memoVersion: String?
    var noteVersion: String?
    var authorKey: String?
    
    var shareableLink: String? {
        guard let address = address else {
            return nil
        }
        return address.markup
    }
    
    var isAppendLinkSearchPresented = false
    var appendLinkSearch = AppendLinkSearchModel()
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case let .setAddress(address):
            return setAddress(
                state: state,
                environment: environment,
                address: address
            )
        case let .setAuthor(author):
            return setAuthor(
                state: state,
                environment: environment,
                author: author
            )
        case .requestDismiss, .requestAuthorDetail, .requestQuoteInNewNote:
            return Update(state: state)
            
        // Rename
        case .appendLinkSearch(let action):
            return MemoViewerDetailMetaSheetAppendLinkSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .presentAppendLinkSearchSheet(let isPresented):
            return presentRenameSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .presentAppendLinkSearchSheetFor(let address):
            return update(
                state: state,
                actions: [
                    .setRenameSearchSubject(address),
                    .presentAppendLinkSearchSheet(true)
                ],
                environment: environment
            )
        case .selectAppendLinkSearchSuggestion(let suggestion):
            return selectRenameSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        }
    }
    
    static func setAddress(
        state: Self,
        environment: Environment,
        address: Slashlink
    ) -> Update<Self> {
        var model = state
        model.address = address
        return Update(state: model)
    }
    
    static func setAuthor(
        state: Self,
        environment: Environment,
        author: UserProfile
    ) -> Update<Self> {
        var model = state
        model.author = author
        return Update(state: model)
    }
    
    static func presentRenameSheet(
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
            action: .appendLinkSearch(
                .setSubject(address)
            ),
            environment: environment
        )
    }
    
    static func selectRenameSuggestion(
        state: Self,
        environment: Environment,
        suggestion: RenameSuggestion
    ) -> Update<Self> {
        var model = state
        model.isAppendLinkSearchPresented = false
        return update(
            state: model,
            action: .appendLinkSearch(.selectSuggestion(suggestion)),
            environment: environment
        )
    }
}

struct MemoViewerDetailMetaSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
        }
        .sheet(isPresented: .constant(true)) {
            MemoViewerDetailMetaSheetView(
                store:
                    Store(
                        state: MemoViewerDetailModel(),
                        environment: AppEnvironment()
                    )
                    .viewStore(
                        get: MemoViewerDetailMetaSheetCursor.get,
                        tag: MemoViewerDetailMetaSheetCursor.tag
                    )
            )
        }
    }
}
