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
    var onViewAuthorProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    HStack {
                        if let slashlink = state.address {
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
                            item: state.shareableLink ?? ""
                        )
                        .disabled(state.shareableLink == nil)
                        
                        Button(
                            action: {
                                onViewAuthorProfile()
                                send(.requestDismiss)
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
                .padding()
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
    }
}

enum MemoViewerDetailMetaSheetAction: Hashable {
    case setAddress(_ address: Slashlink?)
    case requestDismiss
}

struct MemoViewerDetailMetaSheetModel: ModelProtocol {
    typealias Action = MemoViewerDetailMetaSheetAction
    typealias Environment = ()
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetailMetaSheet"
    )
    
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
                    address: Slashlink("@bob/foo")!
                ),
                send: { action in },
                onViewAuthorProfile: {}
            )
        }
    }
}
