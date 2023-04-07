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
    var state: MemoViewerDetailMetaSheetModel
    var send: (MemoViewerDetailMetaSheetAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    HStack {
                        if let slashlink = state.address?.toSlashlink() {
                            SlashlinkBylineView(slashlink: slashlink).theme(
                                petname: Color.primary,
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
                        Button(
                            action: {
                                send(.copyLink)
                            }
                        ) {
                            Label(
                                "Copy link",
                                systemImage: "doc.on.doc"
                            )
                        }
                        .disabled(state.address == nil)
                        .buttonStyle(RowButtonStyle())
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
    case setAddress(_ address: MemoAddress?)
    case copyLink
    case requestDismiss
}

struct MemoViewerDetailMetaSheetModel: ModelProtocol {
    typealias Action = MemoViewerDetailMetaSheetAction
    typealias Environment = PasteboardProtocol
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetailMetaSheet"
    )
    
    var address: MemoAddress?
    var memoVersion: String?
    var noteVersion: String?
    var authorKey: String?
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .setAddress(let address):
            var model = state
            model.address = address
            return Update(state: model)
        case .copyLink:
            return copyLink(
                state: state,
                environment: environment
            )
        case .requestDismiss:
            return Update(state: state)
        }
    }
    
    static func copyLink(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        guard let address = state.address else {
            Self.logger.log("Copy link: (nil)")
            return Update(state: state)
        }
        
        switch address {
        case .local(let slug):
            environment.string = slug.markup
            logger.log("Copy link: \(slug)")
        case .public(let slashlink):
            environment.string = slashlink.markup
            logger.log("Copy link: \(slashlink)")
        }
        
        let fx: Fx<Action> = Just(Action.requestDismiss)
            .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
}

struct MemoViewerDetailMetaSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
        }
        .sheet(isPresented: .constant(true)) {
            MemoViewerDetailMetaSheetView(
                state: MemoViewerDetailMetaSheetModel(
                    address: MemoAddress("public::@bob/foo")!
                ),
                send: { action in }
            )
        }
    }
}
