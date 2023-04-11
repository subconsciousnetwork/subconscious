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
                        MetaTableItemShareLinkView(
                            label: "Copy link",
                            item: state.shareableLink ?? ""
                        )
                        .disabled(state.shareableLink == nil)
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
    
    var shareableLink: String? {
        guard let address = address else {
            Self.logger.log("Copy link: (nil)")
            return nil
        }
        
        switch address {
        case .local(let slug):
            Self.logger.log("Copy link: \(slug)")
            return slug.markup
        case .public(let slashlink):
            Self.logger.log("Copy link: \(slashlink)")
            return slashlink.markup
        }
    }
    
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
        case .requestDismiss:
            return Update(state: state)
        }
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
