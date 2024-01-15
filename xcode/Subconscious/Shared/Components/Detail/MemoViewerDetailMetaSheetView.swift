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
                        }
                        
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
    }
}

enum MemoViewerDetailMetaSheetAction: Hashable {
    case setAddress(_ address: Slashlink)
    case setAuthor(_ author: UserProfile)
    case requestDismiss
    case requestAuthorDetail(_ author: UserProfile)
    case requestQuoteInNewNote(_ address: Slashlink)
}

struct MemoViewerDetailMetaSheetModel: ModelProtocol {
    typealias Action = MemoViewerDetailMetaSheetAction
    typealias Environment = ()
    
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
        case .requestDismiss:
            return Update(state: state)
        case .requestAuthorDetail:
            return Update(state: state)
        case .requestQuoteInNewNote:
            return Update(state: state)
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
