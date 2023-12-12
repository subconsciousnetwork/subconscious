//
//  Toolbar.swift
//  Subconscious
//
//  Created by Ben Follington on 9/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct SyncStatusView: View {
    var status: ResourceStatus
    
    var color: Color {
        switch status {
        case .failed:
            return Color.pending
        case .succeeded:
            return Color.success
        case .pending:
            return Color.pending
        case .initial:
            return .secondary
        }
    }
    
    var label: String {
        switch status {
        case .initial:
            return String(localized: "offline")
        case .pending:
            return String(localized: "syncing...")
        case .failed:
            return String(localized: "pending")
        case .succeeded:
            return String(localized: "up to date")
        }
    }
    
    @State var showLabel = true
    
    var body: some View {
        HStack(spacing: AppTheme.unit2) {
            ZStack {
                Circle()
                    .foregroundStyle(color)
                Circle()
                    .stroke(Color.separator, lineWidth: 0.5)
            }
            .frame(width: 8, height: 8)
        
            Text(showLabel ? label : "")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .transition(.opacity)
                .id("sync-status-label")
                .frame(width: 128, height: 16, alignment: .leading)
                .fixedSize(horizontal: true, vertical: true)
        }
        .onAppear {
            switch status {
            case .succeeded:
                showLabel = false
            default:
                showLabel = true
            }
        }
        .onChange(of: status) { nextStatus in
            withAnimation {
                switch nextStatus {
                case .succeeded:
                    showLabel = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showLabel = false
                        }
                    }
                    break
                default:
                    showLabel = true
                }
            }
        }
    }
}

struct MainToolbar: ToolbarContent {
    @ObservedObject var app: Store<AppModel>
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            SyncStatusView(status: app.state.lastGatewaySyncStatus)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    app.send(.presentSettingsSheet(true))
                }
            ) {
                Image(systemName: "gearshape")
            }
        }
    }
}

struct SettingsToolbarItem: ToolbarContent {
    var app: Store<AppModel>
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    app.send(.presentSettingsSheet(true))
                }
            ) {
                Image(systemName: "gearshape")
            }
        }
    }
}
