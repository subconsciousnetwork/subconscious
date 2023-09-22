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
    
    private var label: String {
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
    
    private var color: Color {
        switch status {
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    var body: some View {
        Label(title: {
            Text(label)
        }, icon: {
            ResourceSyncBadge(status: status)
        })
        .foregroundColor(color)
    }
}

// MARK: Settings

struct SettingsView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = String(localized: "Unknown")
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    content:  {
                        NavigationLink(
                            destination: {
                                ProfileSettingsView(app: app)
                            },
                            label: {
                                LabeledContent(
                                    "Nickname",
                                    value: app.state.nickname
                                )
                                .lineLimit(1)
                                .textSelection(.enabled)
                            }
                        )
                        
                        NavigationLink(
                            destination: {
                                SphereSettingsView(app: app)
                            },
                            label: {
                                LabeledContent(
                                    "Sphere",
                                    value: app.state.sphereIdentity ?? unknown
                                )
                                .lineLimit(1)
                            }
                        )

                        LabeledContent(
                            "Version",
                            value: app.state.sphereVersion ?? unknown
                        )
                        .lineLimit(1)
                        .textSelection(.enabled)
                        
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
                    },
                    header: {
                        Text("Noosphere")
                    },
                    footer: { }
                )
                
                SwiftUI.Link(
                    destination: Config.default.feedbackURL,
                    label: {
                        Text("Share feedback")
                    }
                )
                
                Section(
                    content: {
                        Button(
                            action: {
                                app.send(.requestRecoveryMode(.userInitiated))
                            },
                            label: {
                                Text("Recovery Mode")
                            }
                        )
                        NavigationLink("Developer Settings") {
                            DeveloperSettingsView(app: app)
                        }
                    },
                    footer: {
                        VStack(
                            alignment: .leading,
                            spacing: AppTheme.unit
                        ) {
                            Text("Version: v\(Bundle.main.version ?? unknown) (\(Bundle.main.buildVersion ?? unknown))")
                            Text("Noosphere: \(Config.default.noosphere.version)")
                        }
                    }
                )
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
