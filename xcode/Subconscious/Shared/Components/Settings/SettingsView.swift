//
//  SettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/3/23.
//

import SwiftUI
import ObservableStore

struct GatewaySyncLabel: View {
    var status: ResourceStatus
    @State var spin = false
    
    func label(status: ResourceStatus) -> String {
        switch status {
        case .initial:
            return "Sync with Gateway"
        case .pending:
            return "Syncing..."
        case .failed:
            return "Sync Failed"
        case .succeeded:
            return "Sync Complete"
        }
    }
    
    private func labelColor(status: ResourceStatus) -> Color {
        switch status {
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Label(title: {
                Text(label(status: status))
                    .foregroundColor(labelColor(status: status))
            }, icon: {
                switch (status) {
                case .initial:
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.secondary)
                case .pending:
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.accentColor)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(Animation.linear
                            .repeatForever(autoreverses: false)
                            .speed(0.4), value: spin)
                        .onAppear() {
                            self.spin = true
                        }
                case .succeeded:
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.secondary)
                case .failed:
                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                        .foregroundColor(.red)
                }
            })
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
                    Section(
                        content: {
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
                            .disabled(app.state.gatewayURL.count == 0)
                        }, header: {
                            Text("Gateway")
                        }, footer: {
                            switch (app.state.lastGatewaySyncStatus) {
                            case let .failed(message):
                                Text(message)
                            default:
                                EmptyView()
                            }
                        }
                    )
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
