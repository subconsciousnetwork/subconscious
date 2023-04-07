//
//  MemoViewerDetailMetaSheetView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/6/23.
//

import SwiftUI
import ObservableStore
import os

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
                                send(.copyAddress)
                            }
                        ) {
                            Label(
                                "Copy link",
                                systemImage: "doc.on.doc"
                            )
                        }
                        .disabled(state.address == nil)
                        .buttonStyle(RowButtonStyle())
                        Divider()
                        Button(
                            action: {
                            }
                        ) {
                            Label(
                                "Share",
                                systemImage: "square.and.arrow.up"
                            )
                        }
                        .disabled(state.address == nil)
                        .buttonStyle(RowButtonStyle())
                    }

                    MetaTableView {
                        MetaTableRowView(
                            icon: Image(systemName: "number"),
                            label: Text("Note Revision"),
                            text: Text(verbatim: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf")
                        ) {
                            
                        }
                        MetaTableRowView(
                            icon: Image(systemName: "network"),
                            label: Text("Sphere Revision"),
                            text: Text(verbatim: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf")
                        ) {
                            
                        }
                        MetaTableRowView(
                            icon: Image(systemName: "key"),
                            label: Text("Author Key"),
                            text: Text(verbatim: "0xb794f5ea0ba39494ce8"),
                            hasDivider: false
                        ) {
                            
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
    case setAddress(_ address: MemoAddress)
    case copyAddress
}

protocol MemoViewerDetailMetaSheetEnvironmentProtocol {
    var pasteboard: PasteboardProtocol { get }
}

struct MemoViewerDetailMetaSheetModel: ModelProtocol {
    typealias Action = MemoViewerDetailMetaSheetAction
    typealias Environment = MemoViewerDetailMetaSheetEnvironmentProtocol
    
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
        case .copyAddress:
            return copyAddress(
                state: state,
                environment: environment
            )
        }
    }
    
    static func copyAddress(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        guard let address = state.address else {
            Self.logger.log("Copy address: (nil)")
            return Update(state: state)
        }
        environment.pasteboard.string = address.description
        Self.logger.log("Copied address: \(address)")
        return Update(state: state)
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
