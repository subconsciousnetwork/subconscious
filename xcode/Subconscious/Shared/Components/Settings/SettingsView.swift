//
//  SettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/3/23.
//

import SwiftUI
import ObservableStore

struct GatewaySyncLabel: View {
    var status: GatewaySyncStatus
    @State var spin = false
    
    func label(status: GatewaySyncStatus) -> String {
        switch (status) {
        case .initial:
            return "Sync with Gateway"
        case .inProgress:
            return "Syncing..."
        case .failure:
            return "Sync Failed"
        case .success:
            return "Sync Complete"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                switch (status) {
                case .failure(_):
                    Text(label(status: status))
                        .foregroundColor(.red)
                default:
                    Text(label(status: status))
                        .foregroundColor(.accentColor)
                }
                
                if case .failure(let message) = status {
                    Text("\(message)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            
            Spacer()
            
            switch (status) {
            case .initial:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.secondary)
            case .inProgress:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(Animation.linear
                        .repeatForever(autoreverses: false)
                        .speed(0.4), value: spin)
                    .onAppear() {
                        self.spin = true
                    }
            case .success:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.secondary)
            case .failure:
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    .foregroundColor(.red)
            }
            
        }
    }
}

struct SettingsView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = "Unknown"
    
    var body: some View {
        NavigationStack {
            Form {
                if app.state.isNoosphereEnabled {
                    Section(header: Text("Noosphere")) {
                        NavigationLink(
                            destination: {
                                ProfileSettingsView(app: app)
                            },
                            label: {
                                LabeledContent(
                                    "Nickname",
                                    value: app.state.nickname ?? ""
                                )
                                .lineLimit(1)
                                .textSelection(.enabled)
                            }
                        )
                        LabeledContent(
                            "Sphere",
                            value: app.state.sphereIdentity ?? unknown
                        )
                        .lineLimit(1)
                        .textSelection(.enabled)
                        LabeledContent(
                            "Version",
                            value: app.state.sphereVersion ?? unknown
                        )
                        .lineLimit(1)
                        .textSelection(.enabled)
                    }

                    Section(header: Text("Gateway")) {
                        NavigationLink(
                            destination: {
                                GatewayURLSettingsView(app: app)
                            },
                            label: {
                                LabeledContent(
                                    "Gateway",
                                    value: app.state.gatewayURL
                                )
                                .lineLimit(1)
                            }
                        )
                        Button(
                            action: {
                                app.send(.syncSphereWithGateway)
                            },
                            label: {
                                GatewaySyncLabel(
                                    status: app.state.lastGatewaySyncStatus
                                )
                            }
                        )
                    }
                }
                Section {
                    NavigationLink("Developer Settings") {
                        DeveloperSettingsView(app: app)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        app.send(.presentSettingsSheet(false))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                app.send(.refreshSphereVersion)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
