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

                        MetaTableItemShareLinkView(
                            label: "Share text",
                            item: store.state.shareableText ?? ""
                        )
                        .disabled(store.state.shareableText == nil)
                        
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
    case setShareableText(_ text: String)
    case setAuthor(_ author: UserProfile)
    case setLiked(_ liked: Bool)
    case requestDismiss
    case requestAuthorDetail(_ author: UserProfile)
    case requestQuoteInNewNote(_ address: Slashlink, comment: String? = nil)
    case requestUpdateLikeStatus(_ address: Slashlink, liked: Bool)
    
    /// Tagged actions for append link search sheet
    case appendLinkSearch(AppendLinkSearchAction)
    case presentAppendLinkSearchSheet(_ isPresented: Bool)
    case selectAppendLinkSearchSuggestion(AppendLinkSuggestion)
    
    static func setAppendLinkSearchSubject(_ address: Slashlink?) -> Self {
        .appendLinkSearch(.setSubject(address))
    }
}

// MARK: AppendLinkSearchCursor
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
    var shareableText: String?
    var memoVersion: String?
    var noteVersion: String?
    var authorKey: String?
    var liked: Bool = false
    
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
        case let .setShareableText(text):
            return setShareableText(
                state: state,
                environment: environment,
                text: text
            )
        case let .setAuthor(author):
            return setAuthor(
                state: state,
                environment: environment,
                author: author
            )
        case let .setLiked(liked):
            return setLiked(
                state: state,
                environment: environment,
                liked: liked
            )
        case .requestDismiss, .requestAuthorDetail, .requestQuoteInNewNote,
                .requestUpdateLikeStatus:
            return Update(state: state)
            
        // Append link
        case .appendLinkSearch(let action):
            return MemoViewerDetailMetaSheetAppendLinkSearchCursor.update(
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
    
    static func setShareableText(
        state: Self,
        environment: Environment,
        text: String
    ) -> Update<Self> {
        var model = state
        model.shareableText = text
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
    
    static func setLiked(
        state: Self,
        environment: Environment,
        liked: Bool
    ) -> Update<Self> {
        var model = state
        model.liked = liked
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
