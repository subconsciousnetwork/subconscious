//
//  AppUpgradeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/22/23.
//

import SwiftUI

struct SyncStatusIconView: View {
    var status: ResourceStatus
    
    private var color: Color {
        switch status {
        case .initial:
            return .secondaryIcon
        case .pending:
            return .secondaryIcon
        case .succeeded:
            return .green
        case .failed:
            return .red
        }
    }

    private var systemName: String {
        switch status {
        case .initial:
            return "circle"
        case .pending:
            return "circle"
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "checkmark.circle.trianglebadge.exclamationmark"
        }
    }

    var body: some View {
        Image(systemName: systemName)
            .foregroundColor(color)
    }
}

/// Displays information to the user when app migration / rebuild happening.
struct AppUpgradeView: View {
    var database: ResourceStatus
    var local: ResourceStatus
    var sphere: ResourceStatus

    var body: some View {
        VStack {
            Text("What? Subconscious is evolving!")
                .font(.title2)
            Spacer()
            
            ProgressView()
            Spacer()
            VStack(alignment: .leading, spacing: AppTheme.unit) {
                Label(
                    title: { Text("Upgrading database") },
                    icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                )
                .labelStyle(.titleAndIcon)
                Label(
                    title: { Text("Migrating local notes") },
                    icon: { SyncStatusIconView(status: local) }
                )
                .labelStyle(.titleAndIcon)
                Label(
                    title: { Text("Migrating sphere notes") },
                    icon: { SyncStatusIconView(status: sphere) }
                )
                .labelStyle(.titleAndIcon)
            }
            .multilineTextAlignment(.center)
            .font(.body)
            .foregroundColor(.secondary)

            Spacer()

            Button("Continue", action: {})
                .buttonStyle(LargeButtonStyle())
                .disabled(true)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white)
    }
}

struct AppUpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        AppUpgradeView(
            database: .initial,
            local: .initial,
            sphere: .initial
        )
    }
}
